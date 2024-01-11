module "helloWorld" {
  source = "../src/modules/hello-world"
}

module "ami-builder" {
  source = "../src/modules/ami-builder"
}

output "ami_id" {
  value = module.ami-builder.ami_id
}
