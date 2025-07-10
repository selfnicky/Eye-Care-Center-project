# Eye Care Center Web Application

## Project Overview

This project implements a full-stack web application for an "Eye Care Center," designed to showcase modern cloud-native deployment practices. It features a user interface for managing appointments and subscriptions, backed by a Node.js API and a PostgreSQL database. The entire application is containerized and deployed on Amazon Web Services (AWS) Elastic Kubernetes Service (EKS) using Infrastructure as Code (Terraform).

## Features

* **User Interface:** Intuitive web pages for:
    * Login/Registration
    * Booking Appointments
    * Managing Subscriptions
* **Backend API:** A Node.js API to handle:
    * User authentication (login, registration)
    * Appointment scheduling logic
    * Subscription management logic
* **Database:** Persistent storage using PostgreSQL.
* **Containerization:** Both frontend and backend are Dockerized for consistent environments.
* **Orchestration:** Kubernetes on AWS EKS manages container deployment, scaling, and networking.
* **Infrastructure as Code (IaC):** Terraform defines and provisions all AWS cloud resources, ensuring reproducibility.
* **Networking:** Kubernetes Ingress (Nginx) provides external access and intelligent routing to frontend and backend services.

## Architecture

The application follows a typical microservices-oriented architecture:

1.  **Frontend-App:**
    * **Technology:** HTML, CSS, JavaScript
    * **Purpose:** Static web pages providing the user interface. Makes API calls to the backend.
    * **Deployment:** Docker container, served by Nginx.

2.  **Backend-App:**
    * **Technology:** Node.js (e.g., Express.js)
    * **Purpose:** RESTful API for business logic (authentication, data management).
    * **Deployment:** Docker container.

3.  **Database (RDS PostgreSQL):**
    * **Technology:** PostgreSQL
    * **Purpose:** Stores application data (users, appointments, subscriptions).
    * **Deployment:** Managed service on AWS RDS for high availability and scalability.

4.  **Kubernetes (AWS EKS):**
    * **Control Plane:** AWS EKS manages the Kubernetes control plane.
    * **Worker Nodes:** EC2 instances managed by EKS for running application pods.
    * **Kubernetes Objects:**
        * `Deployments`: Manage the lifecycle and scaling of frontend and backend pods.
        * `Services`: Provide stable network endpoints for pods (ClusterIP for backend, LoadBalancer for Ingress).
        * `Ingress`: An Nginx Ingress Controller handles external HTTP/HTTPS traffic, routing requests to the frontend service (for static assets) and the backend service (for `/api` routes).

5.  **AWS Infrastructure:**
    * **VPC:** Dedicated Virtual Private Cloud for network isolation. Includes public and private subnets.
    * **ECR:** Elastic Container Registry for storing Docker images.
    * **ELB:** Elastic Load Balancer (provisioned by the Ingress Controller) to distribute external traffic.
    * **IAM:** Roles and policies for secure access.

```mermaid
graph TD
    User -- HTTP/HTTPS --> AWS_ELB[AWS Application Load Balancer]
    AWS_ELB -- Route Traffic --> Ingress_Nginx[Kubernetes Ingress Controller (Nginx)]

    subgraph Kubernetes Cluster (AWS EKS)
        Ingress_Nginx -- / --> Frontend_Service[Frontend Service (ClusterIP)]
        Ingress_Nginx -- /api --> Backend_Service[Backend Service (ClusterIP)]

        Frontend_Service --> Frontend_Pods[Frontend Pods]
        Backend_Service --> Backend_Pods[Backend Pods]
    end

    Backend_Pods -- PostgreSQL Client --> AWS_RDS[AWS RDS PostgreSQL]

    style AWS_ELB fill:#FF9900,stroke:#333,stroke-width:2px
    style Ingress_Nginx fill:#0073B7,stroke:#333,stroke-width:2px
    style Frontend_Service fill:#4CAF50,stroke:#333,stroke-width:2px
    style Backend_Service fill:#4CAF50,stroke:#333,stroke-width:2px
    style Frontend_Pods fill:#673AB7,stroke:#333,stroke-width:2px
    style Backend_Pods fill:#673AB7,stroke:#333,stroke-width:2px
    style AWS_RDS fill:#FF9900,stroke:#333,stroke-width:2px
