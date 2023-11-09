output "private_key" {
  value = module.key_pair.private_key_pem
  sensitive = true
}