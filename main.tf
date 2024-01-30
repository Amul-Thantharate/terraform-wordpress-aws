# Genrating the key pair for the EC2 instance. with 4096 bits
resource "tls_private_key" "example" {
    algorithm = "RSA"
    rsa_bits  = 4096
}
# Define the key pair for the EC2 instance.
resource "aws_key_pair" "generated_key" {
    key_name   = var.key_name
    public_key = tls_private_key.example.public_key_openssh
}


# Data source to get the AMI ID of the Amazon Linux 2 AMI.
data "aws_ami" "amazon-2" {
    most_recent = true

    filter {
        name = "name"
        values = ["amzn2-ami-hvm-*-x86_64-ebs"]
    }
    owners = ["amazon"]
}

# Define the security group for the EC2 instance.
resource "aws_security_group" "wordpress" {
    name = "wordpress-sg"
    vpc_id = var.vpc_id
    ingress = [
    for port in [22, 80, 8080] : {
        description      = "TLS from VPC"
        from_port        = port
        to_port          = port
        protocol         = "tcp"
        cidr_blocks      = ["0.0.0.0/0"]
        ipv6_cidr_blocks = []
        prefix_list_ids  = []
        security_groups  = []
        self             = false
        }
    ]
    egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    }
    tags = {
        "key" = "Ec2 instance security group" 
    }
}

# Second security group for the MySQL server.
resource "aws_security_group" "mysql" {
    name = "mysql-sg"
    vpc_id = var.vpc_id
    ingress {
    description      = "mysql"
    from_port       = 0
    protocol        = "-1"
    to_port         = 0
    security_groups = [aws_security_group.wordpress.id]
    }
    egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    }
    tags = {
        "key" = "MySQL server security group" 
    }
}

# Define the WordPress EC2 instance.
resource "aws_instance" "wordpress" {
    ami = data.aws_ami.amazon-2.id
    instance_type = "t2.micro"
    key_name = aws_key_pair.generated_key.key_name
    vpc_security_group_ids = [aws_security_group.wordpress.id]
    subnet_id = var.public_subnet
    connection {
        type        = "ssh"
        user        = "ec2-user"
        private_key = tls_private_key.example.private_key_pem
        host        = aws_instance.wordpress.public_ip
    }

    provisioner "file" {
        source      = "${var.key_name}.pem"
        destination = "/home/ec2-user/${var.key_name}.pem"
    }

    provisioner "remote-exec" {
    inline = [
            "chmod 0400 /home/ec2-user/${var.key_name}.pem",
        ]
    }
    provisioner "file" {
        source      = "wordpress.sh"
        destination = "/home/ec2-user/wordpress.sh"
    }
    provisioner "remote-exec" {
    inline = [
        "chmod +x wordpress.sh",
        "./wordpress.sh",
    ]
}
}

# Define the MySQL EC2 instance.
resource "aws_instance" "my-private-instance" {
    ami = data.aws_ami.amazon-2.id
    instance_type = "t2.micro"
    key_name = aws_key_pair.generated_key.key_name
    vpc_security_group_ids = [aws_security_group.mysql.id]
    subnet_id = var.private_subnet
    user_data              = <<EOF
    #!/bin/bash
    sudo yum update -y
    wget https://repo.mysql.com/mysql-community-release-el7-5.noarch.rpm
    sudo yum install mysql-community-release-el7-5.noarch.rpm -y
    sudo yum install mysql-server -y
    sudo systemctl start mysqld
    sudo systemctl enable mysqld
    mysql -uroot <<MYSQL_SCRIPT
    CREATE USER 'wp_user'@localhost IDENTIFIED BY 'admin@123';
    CREATE DATABASE wp;
    GRANT ALL PRIVILEGES ON wp.* TO 'wp_user'@'localhost';
    MYSQL_SCRIPT
    EOF
    tags = {
        "Name" = "mysql" 
    }
}

