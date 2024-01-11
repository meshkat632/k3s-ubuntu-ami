variable "aws_region" {
  description = "AWS region to deploy to"
  type        = string
  default     = "eu-central-1"
}

variable "aws_profile" {
  description = "AWS profile to use"
  type        = string
  default     = "default"
}

variable "vpc_name" {
  type        = string
  default     = "vpc-k3s-ami-image-builder"
}

variable "vpc_cidr" {
  type        = string
  default     = "10.0.0.0/16"
}

variable "project_name" {
  type        = string
  default     = "k8s-ami-image-builder"
}
