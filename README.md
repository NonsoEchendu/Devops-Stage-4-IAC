# Devops-Stage-4-IAC

# Terraform and Ansible Todo Application Deployment

This repository contains the Infrastructure as Code (IaC) setup for deploying the Todo microservices application using Terraform for infrastructure provisioning and Ansible for configuration management and application deployment.

## Overview

This project automates the entire deployment process:

1. **Terraform** provisions cloud infrastructure (servers, networking, security)
2. **Ansible** configures the servers and deploys the application

The deployment process is fully automated - Terraform dynamically creates Ansible inventory files and triggers the Ansible playbook execution after provisioning is complete.

## Repository Structure

```
terraform-todo-deployment/
├── main.tf
├── variables.tf
├── terraform.tfvars.example
├── templates/
│   ├── inventory.tmpl
│   └── vars.tmpl
└── ansible/
    ├── inventory/
    │   └── .gitkeep
    ├── vars/
    │   └── .gitkeep
    ├── playbook.yml
    └── roles/
        ├── dependencies/
        │   └── tasks/
        │       └── main.yml
        └── deployment/
            ├── tasks/
            │   └── main.yml
            └── templates/
                ├── docker-compose.yml.j2
                ├── dynamic.yaml.j2
                └── env.j2
```

## Prerequisites

- [Terraform >= 1.0.0](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
- [Ansible >= 2.9.0](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html#installing-and-upgrading-ansible-with-pip)
- AWS CLI configured with appropriate credentials
- SSH key pair for accessing EC2 instances

## Infrastructure Components

This repository provisions and configures:

- **VPC** with public and private subnets
- **EC2 instance(s)** for running the Todo application
- **Security Groups** for controlling access to the instances
- **Load Balancer** (optional) for distributing traffic
- **DNS Configuration** (optional) for custom domain setup


## Setup Instructions

### 1. Configure Terraform

1. Clone this repository:
   ```
   git clone https://github.com/yourusername/terraform-todo-deployment.git
   cd terraform-todo-deployment
   ```

2. Create your `terraform.tfvars` file based on the example:
   ```
   cp terraform.tfvars.example terraform.tfvars
   ```

3. Edit `terraform.tfvars` to set your specific configuration values:
   - Cloud provider credentials
   - Server size/type
   - Region/availability zone
   - SSH keys
   - Application repository URL
   - Domain name for SSL/TLS

   ```hcl
    aws_region        = "us-east-1"
    vpc_cidr          = "10.0.0.0/16"
    instance_type     = "t2.medium"
    key_name          = "your-key-name"
    domain_name       = "your-domain.com"
    environment       = "production"
    ```

### 2. Initialize and apply Terraform configuration

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

This will:
- Provision the cloud server(s)
- Configure security groups (open necessary ports)
- Dynamically create Ansible inventory files
- Trigger Ansible playbook execution

## Terraform Resources

The main Terraform configuration (`main.tf`) provisions:

- Cloud server(s) with appropriate sizes
- Security groups for HTTP(S), SSH, and application-specific ports
- Dynamic generation of Ansible inventory and variable files
- Local-exec provisioner to trigger Ansible after successful deployment

## Ansible Automation

The Ansible automation consists of two main roles:

### Dependencies Role

Installs and configures:
- Docker
- Docker Compose
- Other system dependencies

### Deployment Role

Handles application deployment:
- Clones the application repository
- Configures environment variables
- Sets up Docker Compose with the application
- Configures Traefik as a reverse proxy with automatic SSL/TLS

## SSL/TLS Configuration

SSL/TLS is handled by Traefik, which:
- Automatically provisions Let's Encrypt certificates
- Manages certificate renewal
- Provides secure HTTPS access to the application

## Customization

### Adding Cloud Providers

To support additional cloud providers:
1. Add appropriate provider blocks in `main.tf`
2. Update the resource definitions
3. Modify the templates accordingly

### Modifying Application Deployment

To deploy a different application:
1. Update the repository URL in `terraform.tfvars`
2. Modify `docker-compose.yml.j2` to match the application requirements
3. Update environment variables in `env.j2`

## Contributing

1. Fork the repository
2. Create a feature branch
3. Submit a pull request

## Licenses

[MIT License](LICENSE)
