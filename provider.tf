terraform {
    required_version = ">= 0.14.0"
    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = "~> 3.0"
        }
        template = {
            source  = "hashicorp/template"
            version = "~> 2.2"
        }
        tls = {
            source  = "hashicorp/tls"
            version = "~> 3.0"
        }
        local = {
            source  = "hashicorp/local"
            version = "~> 2.1"
        }
    }
    backend "s3" {
        bucket = "terraform-backend-bucket-12"
        key    = "WordPress/terraform.tfstate"
        region = "ap-northeast-1"
        dynamodb_table = "terraform-state-lock"
    }
}

provider "aws" {
    region = var.aws_region
}