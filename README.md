# terraform_modules

Reusable Terraform modules for AWS resources.

## Overview

This repository provides modular Terraform code to deploy AWS infrastructure, including VPC, EC2 instances, and Application Load Balancers (ALB). The modules are designed for reusability and best practices.

## Modules

- **VPC Module** (`modules/vpc`):  
  Creates a VPC with public and private subnets, and customizable security groups.

- **EC2 Module** (`modules/ec2`):  
  Deploys multiple EC2 instances with configurable networking and security group associations.

- **ALB Module** (`modules/alb`):  
  Creates an Application Load Balancer with listeners and target groups.

## Example Usage

Sample `main.tf` usage:

```hcl
module "vpc" {
  source               = "./modules/vpc"
  name                 = "main"
  vpc_cidr             = "10.0.0.0/16"
  azs                  = ["us-east-1a", "us-east-1b"]
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.101.0/24", "10.0.102.0/24"]

  security_groups = {
    "web" = {
      description = "Allow HTTP/S inbound"
      ingress_rules = [
        {
          from_port   = 80
          to_port     = 80
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
        },
        {
          from_port   = 443
          to_port     = 443
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
        },
        {
          from_port   = 22
          to_port     = 22
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
        }
      ]
      egress_rules = [
        {
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
        }
      ]
    },
    "app" = {
      description = "Allow HTTP/S inbound"
      ingress_rules = [
        {
          from_port   = 80
          to_port     = 80
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
        },
        {
          from_port   = 443
          to_port     = 443
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
        },
        {
          from_port   = 22
          to_port     = 22
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
        },
        {
          from_port   = 3601
          to_port     = 3601
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
        }
      ]
      egress_rules = [
        {
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
        }
      ]
    },
    "alb" = {
      description = "Allow HTTP/S inbound"
      ingress_rules = [
        {
          from_port   = 80
          to_port     = 80
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
        }
      ]
      egress_rules = [
        {
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
        }
      ]
    }
  }
}



module "ec2" {
  source = "./modules/ec2"

  instances = merge(
    {
      for i in range(2) : "app-server-${i + 1}" => {
        name                        = "app-server-${i + 1}"
        ami                         = "ami-0f5ee92e2d63afc18"
        instance_type               = "t2.micro"
        subnet_id                   = module.vpc.private_subnet_ids["10.0.101.0/24"]
        key_name                    = file("./terra-key.pub")
        associate_public_ip_address = false
        security_group_ids          = [module.vpc.security_group_ids["app"]]
        tags = {
          ENV = "dev"
        }
      }
    },
    {
      for i in range(1) : "web-server-${i + 1}" => {
        name                        = "web-server-${i + 1}"
        ami                         = "ami-0f5ee92e2d63afc18"
        instance_type               = "t2.micro"
        subnet_id                   = module.vpc.public_subnet_ids["10.0.1.0/24"]
        key_name                    = file("./terra-key.pub")
        security_group_ids          = [module.vpc.security_group_ids["web"]]
        associate_public_ip_address = true
        tags = {
          ENV = "dev"
        }
      }
    }

  )
  tags = {
    project    = "facelog"
    owner      = "vivek_dalsaniya"
    launchDate = "22-may-2025"
  }
}


module "alb" {
  source = "./modules/alb"

  name            = "web-alb"
  vpc_id          = module.vpc.vpc_id
  subnets         = [module.vpc.public_subnet_ids["10.0.1.0/24"], module.vpc.public_subnet_ids["10.0.2.0/24"]]
  security_groups = [module.vpc.security_group_ids["alb"]]

  listeners = [
    {
      port     = 80
      protocol = "HTTP"
      default_action = {
        type             = "forward"
        target_group_key = "app-tg"
      }
      rules = [
        {
          priority         = 10
          path_patterns    = ["/app*"]
          target_group_key = "app-tg"
        },
        {
          priority         = 20
          path_patterns    = ["/web*"]
          target_group_key = "web-tg"
        }
      ]
    }


  ]

  target_groups = {
    "app-tg" = {
      protocol    = "HTTP"
      port        = 80
      target_type = "instance"
      health_check = {
        path                = "/"
        interval            = 30
        timeout             = 5
        healthy_threshold   = 2
        unhealthy_threshold = 2
        matcher             = "200-299"
      }
      targets = [
        for id in data.aws_instances.app.ids : {
          id   = id
          port = 80
        }
      ]
    },
    "web-tg" = {
      protocol    = "HTTP"
      port        = 80
      target_type = "instance"
      health_check = {
        path                = "/"
        interval            = 30
        timeout             = 5
        healthy_threshold   = 2
        unhealthy_threshold = 2
        matcher             = "200-299"
      }
      targets = [
        for id in data.aws_instances.web.ids : {
          id   = id
          port = 80
        }
      ]
    }
  }

  tags = {
    Environment = "dev"
  }
}

```

## Requirements

- Terraform
- AWS CLI
- AWS credentials with permissions

## Inputs and Outputs

Each module has its own set of variables and outputs. Refer to the variables and outputs in each module's `main.tf` or accompanying documentation for details.

## Author

- [vivekdalsaniya12](https://github.com/vivekdalsaniya12)

---

*Use these modules to quickly build and scale AWS infrastructure following best practices!*
