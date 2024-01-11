terraform {

  /*
  cloud {
    organization = "meshkat-experimental"
    workspaces {
      name = "pwc-01-infra-addons"
    }
  }
  */


  required_providers {
    sops = {
      source  = "carlpett/sops"
      version = ">= 0.5"
    }
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.67.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.10.1"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~>1.14.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.22.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.1.0"
    }
    rancher2 = {
      source  = "rancher/rancher2"
      version = "3.2.0"
    }
  }
}


provider "aws" {

  default_tags {
    tags = {
      Environment = "POC"
      Owner       = "meshkat"
      Project     = "pyxis-workload-infrastructure"
    }
  }

}
