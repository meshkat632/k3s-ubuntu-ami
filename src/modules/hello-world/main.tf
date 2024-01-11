resource "random_string" "my_random_string" {
  length = 10
}

output "random_string" {
  value = "${random_string.my_random_string.result}"
}
