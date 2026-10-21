terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "vle8_blue_green" {
  ami           = var.ami_id
  instance_type = "t3.small"

  tags = {
    Name       = "VLE8-BlueGreen-Terraform"
    Experiment = "VLE-8"
    Deployment = "Blue-Green"
  }
}

variable "ami_id" {
  description = "Valid Ubuntu AMI ID for us-east-1"
  type        = string
}
