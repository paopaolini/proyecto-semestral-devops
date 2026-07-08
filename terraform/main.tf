# 1. Configuración del Proveedor AWS
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1" # Región estándar para laboratorios académincos
}

# 2. Grupo de Seguridad (Firewall) para permitir tráfico
resource "aws_security_group" "sg_proyecto" {
  name        = "sg_proyecto_semestral"
  description = "Permitir trafico para SpringBoot y Frontend"

  # Puerto para SSH (Administración)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Puerto para el Frontend (Angular/React)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Puerto para Backend Ventas
  ingress {
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Puerto para Backend Despachos
  ingress {
    from_port   = 8082
    to_port     = 8082
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Salida libre a internet
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 3. Instancia EC2 (Servidor Virtual) donde correrá Docker / App
resource "aws_instance" "servidor_proyecto" {
  ami           = "ami-0c7217cdde317cfec" # Ubuntu Server 22.04 LTS en us-east-1
  instance_type = "t2.micro"             # Capa gratuita

  vpc_security_group_ids = [aws_security_group.sg_proyecto.id]

  tags = {
    Name = "Servidor-Proyecto-Semestral"
    Env  = "DevOps"
  }
}
