terraform {
  backend "s3" {
    bucket         = "myeyecare" # Replace with a unique bucket name
    key            = "eye-care-website/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "myeyecare-terraform-state-lock-table" # Optional, but highly recommended for state locking
  }
}