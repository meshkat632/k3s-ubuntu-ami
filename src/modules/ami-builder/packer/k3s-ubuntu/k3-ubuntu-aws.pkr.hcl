#############################################
variable "ami_prefix" {
  type    = string
  default = "k3s-ubuntu-aws-redis"
}

variable "ami_builder_instance_type" {
  type    = string
  default = "t2.micro"
}
variable "source_ami" {
  type    = string
  default = "ami-0faab6bdbac9486fb"
}

variable "vpc_id" {
  type    = string
}

variable "subnet_id" {
  type    = string
}

variable "aws_region" {
  type    = string
  default = "eu-central-1"
}


#############################################
locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
}

packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.8"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

source "amazon-ebs" "ubuntu" {
  ami_name                    = "${var.ami_prefix}-${local.timestamp}"
  instance_type               = var.ami_builder_instance_type #"t2.micro"
  region                      = var.aws_region #"eu-central-1"
  source_ami                  = var.source_ami #"ami-0faab6bdbac9486fb"
  ssh_username                = "ubuntu"
  vpc_id                      = var.vpc_id #"vpc-04ab6a593a089d495"
  subnet_id                   = var.subnet_id #"subnet-00a16d51844994b73"
  associate_public_ip_address = true
  tags = {
    Name          = "${var.ami_prefix}-${local.timestamp}"
    OS_Version    = "Ubuntu"
    Release       = "Latest"
    Base_AMI_Name = "{{ .SourceAMIName }}"
    Extra         = "{{ .SourceAMITags.TagName }}"
  }
}

build {
  name = "${var.ami_prefix}-${local.timestamp}"
  sources = [
    "source.amazon-ebs.ubuntu"
  ]
  provisioner "shell" {
    environment_vars = [
      "FOO=hello world",
    ]
    inline = [
      "echo Installing Redis",
      "sleep 30",
      "sudo apt-get update",
      "sudo apt-get install -y redis-server",
      "echo \"FOO is $FOO\" > example.txt",
    ]
  }



  /*
  provisioner "file" {
    source = "example.txt"
    destination = "/tmp/example.txt"
  }

  provisioner "file" {
    source = "my-config.yaml"
    destination = "/tmp/my-config.yaml"
  }

  provisioner "shell" {
    inline = [
      "echo This provisioner runs last",
      "ls -la",
      "cat /tmp/example.txt"
    ]
  }

  provisioner "shell" {
    inline = ["./provision.sh"]
  }
  */
}
