# create vpc
resource "aws_vpc" "todo_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "todo_vpc"
  }
}

# create public subnet
resource "aws_subnet" "todo_public_subnet" {
  vpc_id                  = aws_vpc.todo_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "${var.aws_region}a"

  tags = {
    Name = "todo_public_subnet"
  }
}

# create internet gateway
resource "aws_internet_gateway" "todo_igw" {
  vpc_id = aws_vpc.todo_vpc.id

  tags = {
    Name = "todo_igw"
  }
}

# create route table
resource "aws_route_table" "todo_route_table" {
  vpc_id = aws_vpc.todo_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.todo_igw.id
  }
}

# associate route table with subnet
resource "aws_route_table_association" "todo_route_assoc" {
  subnet_id      = aws_subnet.todo_public_subnet.id
  route_table_id = aws_route_table.todo_route_table.id
}

# create security group
resource "aws_security_group" "todo_sg" {
  name   = "todo_sg"
  vpc_id = aws_vpc.todo_vpc.id

  tags = {
    Name = "todo_sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "todo_sg_allow_ssh" {
  security_group_id = aws_security_group.todo_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "todo_sg_http" {
  security_group_id = aws_security_group.todo_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "todo_sg_https" {
  security_group_id = aws_security_group.todo_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_ingress_rule" "todo_sg_traefik" {
  security_group_id = aws_security_group.todo_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 8080
  ip_protocol       = "tcp"
  to_port           = 8080
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.todo_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

# create ec2 instance
resource "aws_instance" "todo_instance" {
  ami                         = var.ami
  instance_type               = var.instance_type
  key_name                    = var.key_name
  subnet_id                   = aws_subnet.todo_public_subnet.id
  vpc_security_group_ids      = [aws_security_group.todo_sg.id]
  associate_public_ip_address = true

  root_block_device {
    volume_size = 16
    volume_type = "gp2"
  }

  tags = {
    Name = "todo_instance"
  }

  # Wait for the instance to be fully available before proceeding
  provisioner "remote-exec" {
    inline = ["echo 'Server is ready!'"]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.private_key_path)
      host        = self.public_ip
    }
  }
}

# Create Route53 record for the domain
resource "aws_route53_record" "domain" {
  count   = var.domain_name != "" ? 1 : 0
  zone_id = var.route53_zone_id
  name    = var.domain_name
  type    = "A"
  ttl     = 300
  records = [aws_instance.todo_instance.public_ip]
}

# Create subdomains for the APIs
resource "aws_route53_record" "auth_subdomain" {
  count   = var.domain_name != "" ? 1 : 0
  zone_id = var.route53_zone_id
  name    = "auth.${var.domain_name}"
  type    = "A"
  ttl     = 300
  records = [aws_instance.todo_instance.public_ip]
}

resource "aws_route53_record" "todos_subdomain" {
  count   = var.domain_name != "" ? 1 : 0
  zone_id = var.route53_zone_id
  name    = "todos.${var.domain_name}"
  type    = "A"
  ttl     = 300
  records = [aws_instance.todo_instance.public_ip]
}

resource "aws_route53_record" "users_subdomain" {
  count   = var.domain_name != "" ? 1 : 0
  zone_id = var.route53_zone_id
  name    = "users.${var.domain_name}"
  type    = "A"
  ttl     = 300
  records = [aws_instance.todo_instance.public_ip]
}

# Generate Ansible inventory file
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/templates/inventory.tmpl", {
    ip_address   = aws_instance.todo_instance.public_ip
    ssh_user     = "ubuntu"
    ssh_key_file = var.private_key_path
    domain_name  = var.domain_name
    admin_email  = var.admin_email
  })
  filename = "${path.module}/ansible/inventory/hosts.yml"

  depends_on = [aws_instance.todo_instance]
}

# Generate Ansible variables file
resource "local_file" "ansible_vars" {
  content = templatefile("${path.module}/templates/vars.tmpl", {
    domain_name  = var.domain_name
    admin_email  = var.admin_email
    git_repo_url = var.git_repo_url
    git_branch   = var.git_branch
  })
  filename = "${path.module}/ansible/vars/main.yml"

  depends_on = [aws_instance.todo_instance]
}

# Run Ansible playbook
resource "null_resource" "ansible_provisioner" {
  triggers = {
    instance_id = aws_instance.todo_instance.id
  }

  provisioner "local-exec" {
    command = "cd ${path.module}/ansible && ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i inventory/hosts.yml playbook.yml -vvv"
  }

  depends_on = [local_file.ansible_inventory, local_file.ansible_vars]
}
