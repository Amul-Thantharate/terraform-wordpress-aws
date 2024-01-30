output "wordpress" {
    value = aws_instance.wordpress.public_ip
}

output "mysql" {
    value = aws_instance.my-private-instance.private_ip
}

output "private_key" {
    value     = tls_private_key.example.private_key_pem
    sensitive = true
}
