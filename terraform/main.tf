terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configuración del proveedor compatible con AWS Academy
provider "aws" {
  region = "us-east-1"
}

# 1. Red Aislada Exigida por la Pauta (VPC)
resource "aws_vpc" "vpc_produccion" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = { Name = "vpc-sistema-produccion" }
}

# 2. Subred Pública donde apuntará el tráfico de Internet
resource "aws_subnet" "subred_publica" {
  vpc_id                  = aws_vpc.vpc_produccion.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"
  tags = { Name = "subred-publica-proyecto" }
}

# 3. Internet Gateway para conectar la VPC a Internet
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc_produccion.id
  tags   = { Name = "igw-proyecto" }
}

# 4. Tabla de ruteo para habilitar la salida pública
resource "aws_route_table" "rt_publica" {
  vpc_id = aws_vpc.vpc_produccion.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "rt-publica-proyecto" }
}

resource "aws_route_table_association" "rta_publica" {
  subnet_id      = aws_subnet.subred_publica.id
  route_table_id = aws_route_table.rt_publica.id
}

# 5. Grupo de Seguridad con Reglas Restrictivas (Seguridad Básica / Hardening)
resource "aws_security_group" "sg_seguro" {
  name        = "sg-reglas-restrictivas"
  description = "Permitir solo puertos minimos requeridos"
  vpc_id      = aws_vpc.vpc_produccion.id

  # Entrada Puerto 80 para el Frontend
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Entrada Puertos para los Backends
  ingress {
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8082
    to_port     = 8082
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Salida libre a Internet
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 6. Instancia EC2 donde correrá Docker orquestado en producción
resource "aws_instance" "servidor_produccion" {
  ami           = "ami-0c7217cdde317cfec" # Ubuntu Server 22.04 LTS en us-east-1
  instance_type = "t2.micro"             # Capa gratuita admitida por el laboratorio
  subnet_id     = aws_subnet.subred_publica.id
  vpc_security_group_ids = [aws_security_group.sg_seguro.id]

  # Inyección automatizada de Docker para encender el docker-compose al iniciar
  user_data = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y docker.io docker-compose
              systemctl start docker
              systemctl enable docker
              EOF

  tags = {
    Name = "Servidor-Produccion-EFT"
    Env  = "Produccion"
  }
}
