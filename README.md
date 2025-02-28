# Devops-Stage-4-IAC

# Terraform and Ansible Todo Application Deployment

This repository contains the Infrastructure as Code (IaC) setup for deploying the Todo microservices application using Terraform for infrastructure provisioning and Ansible for configuration management and application deployment.

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

- Terraform >= 1.0.0
- Ansible >= 2.9.0
- AWS CLI configured with appropriate credentials
- SSH key pair for accessing EC2 instances

## Infrastructure Components

This repository provisions and configures:

- **VPC** with public and private subnets
- **EC2 instance(s)** for running the Todo application
- **Security Groups** for controlling access to the instances
- **Load Balancer** (optional) for distributing traffic
- **DNS Configuration** (optional) for custom domain setup

## Getting Started

### 1. Configure Terraform variables

Create a `terraform.tfvars` file in the terraform directory:

You can copy an example of the `terraform.tfvars.example` file using

```bash
cp terraform.tfvars.example terraform.tfvars
```

```hcl
aws_region        = "us-east-1"
vpc_cidr          = "10.0.0.0/16"
instance_type     = "t2.medium"
key_name          = "your-key-name"
domain_name       = "michaeloxo.tech"
environment       = "production"
```

### 2. Initialize and apply Terraform configuration

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

Terraform will provision the infrastructure and generate:
- An Ansible inventory file at `../ansible/inventory/hosts`
- Variables for Ansible at `../ansible/group_vars/all.yml`

### 3. Run Ansible playbook to deploy the application

```bash
cd ../ansible
ansible-playbook -i inventory/hosts site.yml
```

## Configuration Details

### Terraform Configuration

The main components of the Terraform configuration:

- **VPC Module**: Creates a VPC with public and private subnets, an internet gateway, and route tables
- **Compute Module**: Provisions EC2 instances with the specified AMI and instance type
- **Security Module**: Sets up security groups for the instances and load balancer

### Ansible Roles

The deployment process uses several Ansible roles:

- **common**: Sets up basic server configuration including timezone, system packages, and security settings
- **docker**: Installs Docker and Docker Compose
- **deployment**: Deploys the Todo application using Docker Compose

### Application Deployment

The deployment role:

1. Creates necessary directories for the application
2. Copies configuration templates (docker-compose.yml, Traefik configs, etc.)
3. Generates the `.env` file with environment variables
4. Pulls Docker images (or builds them if needed)
5. Starts the application with Docker Compose

## Environment Variables

The application requires the following environment variables, which can be set in `ansible/group_vars/all.yml`:

```yaml
# Database Configuration
db_host: your-db-host
db_port: your-db-port
db_user: your-db-user
db_password: your-db-password
db_name: your-db-name

# Redis Configuration
redis_host: redis-queue
redis_port: 6379

# JWT Configuration
jwt_secret: your-jwt-secret
jwt_expiration: 3600

# Domain Configuration
domain_name: michaeloxo.tech

# Email for Let's Encrypt
acme_email: your-email@example.com
```

## Middleware Configuration

The Traefik middleware configuration is defined in the `dynamic.yaml.j2` template. Important notes:

- All middlewares defined in the dynamic configuration must be referenced with `@file` in Docker Compose labels
- Correct middleware references in docker-compose.yml:
  ```yaml
  - "traefik.http.routers.auth-api-path.middlewares=auth-strip-prefix@file,global-middleware@file"
  - "traefik.http.routers.users-api-path.middlewares=users-strip-prefix@file,global-middleware@file"
  - "traefik.http.routers.todos-api-path.middlewares=todos-strip-prefix@file,global-middleware@file"
  ```

## Scaling

To scale the application:

1. Update the `instance_count` variable in `terraform.tfvars`
2. Run `terraform apply` to provision additional instances
3. Ansible will automatically deploy to all instances in the inventory

## Backups and Disaster Recovery

- **State Files**: Terraform state can be stored in an S3 backend with state locking via DynamoDB
- **Configuration**: All configuration is version-controlled in this repository
- **Data**: For data persistence, consider using managed database services or implementing backup strategies

## Troubleshooting

### Common Terraform Issues

- **State Lock Issues**: If a previous run failed, you might need to release the state lock:
  ```bash
  terraform force-unlock LOCK_ID
  ```

- **Resource Limits**: Check AWS service limits if provisioning fails due to capacity constraints

### Common Ansible Issues

- **SSH Connection Issues**: Ensure your SSH key is correctly configured and security groups allow SSH access
- **Docker Issues**: Check Docker service status and ensure Docker Compose is installed correctly
- **Middleware Errors**: If you see errors like `middleware "X@docker" does not exist`, ensure you're using `@file` suffix for file-based middlewares

## CI/CD Integration

This repository can be integrated with CI/CD pipelines:

1. Create a pipeline that runs `terraform plan` for pull requests
2. On merge to main, run `terraform apply` followed by the Ansible playbook
3. Implement approval gates for production deployments

## Security Considerations

- Use AWS IAM roles with least privilege
- Store sensitive data in encrypted form (using AWS KMS, HashiCorp Vault, etc.)
- Regularly update AMIs and Docker images
- Implement network security at multiple layers (VPC, security groups, application firewalls)

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.