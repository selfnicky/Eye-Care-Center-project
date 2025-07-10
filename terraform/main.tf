# --- Data Sources ---
data "aws_availability_zones" "available" {} # To get AZ names dynamically

# MODIFIED: Data source to get the latest available PostgreSQL version (less specific)
data "aws_rds_engine_version" "postgres_any" {
  engine = "postgres"
  # Removed 'version = "14.latest"' to make it less restrictive
  # This will now attempt to find any available PostgreSQL version.
}


# --- VPC and Networking ---
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "eye-care-vpc"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "eye-care-igw"
  }
}

# Public Subnets (for Load Balancer, and possibly EKS worker nodes initially)
resource "aws_subnet" "public" {
  count               = 2 # Deploy in 2 Availability Zones
  vpc_id              = aws_vpc.main.id
  cidr_block          = "10.0.${count.index + 1}.0/24"
  availability_zone   = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  tags = {
    Name = "eye-care-public-subnet-${count.index}"
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "owned" # Tag for EKS auto-discovery
    "kubernetes.io/role/elb"                      = "1"      # Tag for EKS Load Balancer auto-discovery
  }
}

# Private Subnets (for RDS, and ideally EKS worker nodes for better security)
resource "aws_subnet" "private" {
  count             = 2 # Deploy in 2 Availability Zones
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index + 11}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = {
    Name = "eye-care-private-subnet-${count.index}"
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "owned" # Tag for EKS auto-discovery
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "eye-care-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# --- Security Groups ---
resource "aws_security_group" "eks_cluster" {
  name        = "eye-care-eks-cluster-sg"
  description = "Security group for EKS cluster control plane"
  vpc_id      = aws_vpc.main.id
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # Restrict this more in production
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "eks_nodes" {
  name        = "eye-care-eks-node-sg"
  description = "Security group for EKS worker nodes"
  vpc_id      = aws_vpc.main.id
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    # Allow traffic from EKS control plane
    security_groups = [
      aws_security_group.eks_cluster.id
    ]
    # ADDED: Allow all traffic from within the VPC CIDR (for node-to-node communication)
    cidr_blocks = [aws_vpc.main.cidr_block]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "eye-care-eks-node-sg"
  }
}

resource "aws_security_group" "rds_sg" {
  name        = "eye-care-rds-sg"
  description = "Allow traffic to RDS from EKS worker nodes"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 5432 # PostgreSQL default port
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_nodes.id] # Allow EKS nodes to connect
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- ECR Repositories ---
resource "aws_ecr_repository" "frontend_app" {
  name                 = "frontend-app"
  image_tag_mutability = "MUTABLE" # Or IMMUTABLE in production for stricter tag management
  image_scanning_configuration {
    scan_on_push = true
  }
  tags = {
    Name = "frontend-app-repo"
  }
}

resource "aws_ecr_repository" "backend_app" {
  name                 = "backend-app"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
  tags = {
    Name = "backend-app-repo"
  }
}

# --- RDS Database (PostgreSQL Example) ---
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "eye-care-rds-subnet-group"
  subnet_ids = aws_subnet.private[*].id # RDS should be in private subnets
  tags = {
    Name = "eye-care-rds-subnet-group"
  }
}

resource "aws_db_instance" "eye_care_db" {
  identifier                  = "eye-care-db-instance"
  engine                      = "postgres"
  # MODIFIED: Use the dynamic version from the less restrictive data source
  engine_version              = data.aws_rds_engine_version.postgres_any.version
  instance_class              = "db.t3.micro" # Cost-effective for dev/test
  allocated_storage           = 20         # Minimum 20GB for gp2
  storage_type                = "gp2"
  storage_encrypted           = true
  username                    = var.db_username
  password                    = var.db_password # Pulled from terraform.tfvars
  db_subnet_group_name        = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids      = [aws_security_group.rds_sg.id]
  skip_final_snapshot         = true # Set to false in production
  apply_immediately           = true # For faster changes during dev/test
  publicly_accessible         = false # Crucial for security: DB should NOT be public
  multi_az                    = false # Set to true for high availability in production
  final_snapshot_identifier   = "eye-care-db-final-snapshot" # Required if skip_final_snapshot is false
  tags = {
    Name = "eye-care-database"
  }
}

# --- EKS Cluster ---
resource "aws_iam_role" "eks_cluster_role" {
  name = "eye-care-eks-cluster-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

resource "aws_iam_role_policy_attachment" "eks_vpc_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController" # For VPC CNI
  role       = aws_iam_role.eks_cluster_role.name
}

resource "aws_eks_cluster" "eye_care_cluster" {
  name     = var.eks_cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn
  vpc_config {
    subnet_ids              = concat(aws_subnet.public[*].id, aws_subnet.private[*].id)
    security_group_ids      = [aws_security_group.eks_cluster.id]
    endpoint_private_access = false # Set to true for private access only
    endpoint_public_access  = true  # Set to false if endpoint_private_access is true and you don't need public access
  }
  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_iam_role_policy_attachment.eks_vpc_cni_policy,
  ]
  tags = {
    Name = "eye-care-eks-cluster"
  }
}

resource "aws_iam_role" "eks_node_role" {
  name = "eye-care-eks-node-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_node_worker_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_node_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_node_registry_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly" # Allow nodes to pull from ECR
  role       = aws_iam_role.eks_node_role.name
}


resource "aws_eks_node_group" "eye_care_nodes" {
  cluster_name    = aws_eks_cluster.eye_care_cluster.name
  node_group_name = "eye-care-node-group"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = aws_subnet.public[*].id # Nodes can be in public or private subnets
  instance_types  = ["t3.medium"] # Choose appropriate instance type
  disk_size       = 20 # GB

  # Apply the security group created for nodes
  remote_access {
    ec2_ssh_key         = "mykey2" # Using the provided SSH key name
    source_security_group_ids = [aws_security_group.eks_nodes.id]
  }

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  tags = {
    Name = "eye-care-eks-node-group"
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_node_worker_policy,
    aws_iam_role_policy_attachment.eks_node_cni_policy,
    aws_iam_role_policy_attachment.eks_node_registry_policy,
  ]
}