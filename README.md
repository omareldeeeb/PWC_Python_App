# Python Application Deployment on AWS EKS 

This repository contains all the necessary files and instructions to containerize a Python application using Docker, create an Amazon EKS cluster on AWS, and deploy the application using Kubernetes manifests.

## Table of Contents

- [Dockerizing the Python Application]
- [Setting Up Amazon EKS Cluster]
- [Creating the manifests file]
- [Deploying the Application to EKS]
- [Cleanup]

## Dockerizing the Python Application

1. **Create a `Dockerfile`:**

   The Dockerfile will be used to create a Docker image for the Python application.

   ```dockerfile
   # Use the official Python image from the Docker Hub
   FROM python:3

   # Set the working directory
   WORKDIR /app

   # Copy the requirements file
   COPY requirements.txt ./

   # Install dependencies
   RUN pip install --no-cache-dir -r requirements.txt

   # Copy the rest of the application code
   COPY . .

   # Expose the application port
   EXPOSE 80

   # Command to run the application
   CMD ["python", "run.py"]

2. Run These commands  to build, push the docker image:

docker build -t python-app .

aws ecr get-login-password --region <region> | docker login --username AWS --password-stdin <aws_account_id>.dkr.ecr.<region>.amazonaws.com

aws ecr create-repository --repository-name python-app --region <region>

docker tag python-app:latest <aws_account_id>.dkr.ecr.<region>.amazonaws.com/python-app:latest

docker push <aws_account_id>.dkr.ecr.<region>.amazonaws.com/python-app:latest
#################################################################################################################

## Setting Up Amazon EKS Cluster
# Create the VPC and the Subnets 

        module "vpc" {
        source = "terraform-aws-modules/vpc/aws"

        name = "my-vpc"
        cidr = "10.0.0.0/16"

        azs             = ["eu-west-1a", "eu-west-1b"]
        private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]

        tags = {
            Terraform = "true"
            Environment = "EKS"
        }
        }

# EKS Creation on AWS

        module "eks" {
        source  = "terraform-aws-modules/eks/aws"
        version = "20.24.0"

        cluster_name    = "my-cluster"
        cluster_version = "1.30"

        cluster_endpoint_public_access  = true

        cluster_addons = {
            coredns                = {}
            eks-pod-identity-agent = {}
            kube-proxy             = {}
            vpc-cni                = {}
        }

        vpc_id                   = "vpc-06c3b7d96aaa79150"
        subnet_ids               = ["subnet-022b52ee805b6a69d", "subnet-0b2ce2701b26aa7e9"]
        control_plane_subnet_ids = ["subnet-022b52ee805b6a69d", "subnet-0b2ce2701b26aa7e9"]

        eks_managed_node_group_defaults = {
            instance_types = ["t2.micro", "t2.micro"]
        }

        eks_managed_node_groups = {
            lab = {
            # Starting on 1.30, AL2023 is the default AMI type for EKS managed node groups
            ami_type       = "AL2023_x86_64_STANDARD"
            instance_types = ["t2.micro"]

            min_size     = 1
            max_size     = 2
            desired_size = 1
            key_name = "my-eks-keypair" 
            }
        }

        tags = {
            Environment = "EKS PWC"
            Terraform   = "true"
        }
        }

3. Run these terraform commands

        terraform init
        terraform plan
        terraform apply

#########################################################################################################

# Creating the manifests files (Deployment.yaml & Service.yaml)

1. Create the deployment.yaml file

        apiVersion: apps/v1
        kind: Deployment
        metadata:
        name: pwc-python-app
        labels:
            app: pwc-python-app
        spec:
        template:
            metadata:
            labels:
                app: pwc-python-app
            spec:
            containers:
            - name: python-container
                image: 586710795513.dkr.ecr.eu-west-1.amazonaws.com/default/python:latest
                ports:
                - containerPort: 80

        replicas: 2
        selector:
            matchLabels:
            app: pwc-python-app

2. Create the Service.yaml file

        apiVersion: v1 
        kind: Service
        metadata:
        name: pwc-python-app
        spec:
        type: LoadBalancer
        ports:
        - port: 80
            targetPort: 80
            NodePort: 30008
        selector:
            app: pwc-python-app

###################################################################################

Deploying on the EKS

1. Connect to the cluster by running this command:

        aws eks update-kubeconfig --region eu-west-1 --name my-cluster

2. Apply the YAML files to create the deployment and the service:

        kubectl apply -f deployment.yaml
        kubectl apply -f service.yaml

3. Verify the resources are created

        kubectl get pods
        kubectl get services
        kubectl get deployments

####################################################################################

Cleanup 

1. Delete the K8S resources 

        kubectl delete -f deployment.yaml
        kubectl delete -f service.yaml

2. Destroy the EKS cluster using Terraform
        
        terraform destroy