resource "local_file" "packer-values-file" {
  content  = templatefile("${path.module}/packer-values.json.template", {
    vpc_id: module.vpc.vpc_id,
    subnet_id: module.vpc.public_subnets[0]
  })
  filename = "${path.module}/packer-values.json"
}

output "packer_values" {
  value = resource.local_file.packer-values-file.content
}


resource "null_resource" "build_ami" {
  depends_on = [local_file.packer-values-file]
  # Trigger Packer when this resource is created
  /*
  triggers = {
    build_number = timestamp()
  }
  */
  /*
  provisioner "local-exec" {
    command = "packer build -var 'aws_region=${var.aws_region}' packer-template.json"
  }
  */
  provisioner "local-exec" {
    #/Users/meshkat/Projects/ververica/poc-pyxis-image-builder/terraform/packer/k3s-ubuntu/k3-ubuntu-aws.pkr.hcl
    #command = "cat packer/k3s-ubuntu/k3-ubuntu-aws.pkr.hcl"
    command = "packer build -var-file=${path.module}/packer-values.json ${path.module}/packer/k3s-ubuntu/k3-ubuntu-aws.pkr.hcl -machine-readable | tee ${path.module}/packer_output.txt"
  }
  provisioner "local-exec" {
    #/Users/meshkat/Projects/ververica/poc-pyxis-image-builder/terraform/packer/k3s-ubuntu/k3-ubuntu-aws.pkr.hcl
    #command = "cat packer/k3s-ubuntu/k3-ubuntu-aws.pkr.hcl"
    command = "${path.module}/scripts/get_ami_id.sh ${path.module}/packer_output.txt ${path.module}/packer_build_result.json"
  }
}



data "external" "packer_build_result" {
  depends_on = [null_resource.build_ami]
  program = ["bash", "${path.module}/scripts/json-file-data-source.sh"]
  query = {
    file = "${path.module}/packer_build_result.json"
  }
}


output "ami_id" {
  value = data.external.packer_build_result.result
}
