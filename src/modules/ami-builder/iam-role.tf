/*
terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "2.2.2"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "4.37.0"
    }
  }
}

# The provider for AWS, using the profile and region from the variables

provider "aws" {
  profile = var.aws_profile
  region  = var.aws_region
}

*/
####################
# User and group for packer
####################

# Create the user for packer

resource "aws_iam_user" "packer_user" {
  name = "packer_user"
  path = "/"
}

# Create the group for packer

resource "aws_iam_group" "packer_group" {
  name = "packer_group"
  path = "/"
}

# Add the user to the group

resource "aws_iam_group_membership" "packer_group_membership" {
  name = "packer_group_membership"

  users = [
    "${aws_iam_user.packer_user.name}",
  ]

  group = aws_iam_group.packer_group.name
}

####################
# The packer role which can be assumed by the packer user or an EC2 instance
#
# A role needs to be allowed to assume in both directions. The role needs to
# specify which entities can assume it, and the entities need to specify which
# roles they can assume.
####################

# This trusted entities policy document specifies which user, or specific EC2 instances, can assume the packer role below.

data "aws_iam_policy_document" "trusted_entities_policy_document" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = [aws_iam_user.packer_user.arn]
    }
  }
}

# Create the role for packer and connect the trusted entities policy document to the role.

resource "aws_iam_role" "packer_role" {
  name               = "packer_role"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.trusted_entities_policy_document.json
}


####################
# The policy for the packer role from the packer documentation https://developer.hashicorp.com/packer/plugins/builders/amazon#iam-task-or-instance-role
#
# These are the permissions needed to create an AMI. These permissions are given to the packer role, which can be assumed by the packer user, or an EC2 instance.
####################

# The policy document to be attached to the packker_role_policy below

data "aws_iam_policy_document" "packer_role_policy_document" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:AttachVolume",
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:CopyImage",
      "ec2:CreateImage",
      "ec2:CreateKeypair",
      "ec2:CreateSecurityGroup",
      "ec2:CreateSnapshot",
      "ec2:CreateTags",
      "ec2:CreateVolume",
      "ec2:DeleteKeyPair",
      "ec2:DeleteSecurityGroup",
      "ec2:DeleteSnapshot",
      "ec2:DeleteVolume",
      "ec2:DeregisterImage",
      "ec2:DescribeImageAttribute",
      "ec2:DescribeImages",
      "ec2:DescribeInstances",
      "ec2:DescribeInstanceStatus",
      "ec2:DescribeRegions",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSnapshots",
      "ec2:DescribeSubnets",
      "ec2:DescribeTags",
      "ec2:DescribeVolumes",
      "ec2:DetachVolume",
      "ec2:GetPasswordData",
      "ec2:ModifyImageAttribute",
      "ec2:ModifyInstanceAttribute",
      "ec2:ModifySnapshotAttribute",
      "ec2:RegisterImage",
      "ec2:RunInstances",
      "ec2:StopInstances",
      "ec2:TerminateInstances"
    ]
    resources = ["*"]
  }
}

# Connect the policy document to the policy

resource "aws_iam_policy" "packer_role_policy" {
  name        = "packer_role_policy"
  path        = "/"
  description = "The role for packer to create the AMI"
  policy      = data.aws_iam_policy_document.packer_role_policy_document.json
}

# Attach the permissions policy to the role created above. This is what allows the role to create the AMI.

resource "aws_iam_role_policy_attachment" "packer_role_policy_attachment" {
  role       = aws_iam_role.packer_role.name
  policy_arn = aws_iam_policy.packer_role_policy.arn
}

####################
# The policy used by aws_iam_policy.assume_packer_role_policy to assume the packer role
#
# This policy allows the packer user to TRY to assume the packer role. You have to add the packer user to the trusted entities policy document to allow the user to assume the role.
####################

# The policy document to be attached to the assume_packer_role_policy below

data "aws_iam_policy_document" "assume_packer_role_policy_document" {
  statement {
    effect    = "Allow"
    actions   = ["sts:AssumeRole"]
    resources = [aws_iam_role.packer_role.arn]
  }
}

# Connect the policy document above to the policy

resource "aws_iam_policy" "assume_packer_role_policy" {
  name        = "assume_packer_role_policy"
  path        = "/"
  description = "The policy to assume the role for Packer"
  policy      = data.aws_iam_policy_document.assume_packer_role_policy_document.json
}

# Attach the policy above to the group to allow the group to assume the packer role

resource "aws_iam_group_policy_attachment" "assume_packer_role_policy_attachment" {
  group      = aws_iam_group.packer_group.name
  policy_arn = aws_iam_policy.assume_packer_role_policy.arn
}

####################
# Create the access key for packer and save it to a file for packer to use
####################

resource "aws_iam_access_key" "packer_access_key" {
  user = aws_iam_user.packer_user.name
}

resource "local_sensitive_file" "packer_env_file" {
  filename = "../packer/packer.pkrvar.hcl"
  content  = <<-EOF
packer_access_key = "${aws_iam_access_key.packer_access_key.id}"
packer_secret_key = "${aws_iam_access_key.packer_access_key.secret}"
packer_region     = "${var.aws_region}"
packer_role_arn   = "${aws_iam_role.packer_role.arn}"
EOF
}
