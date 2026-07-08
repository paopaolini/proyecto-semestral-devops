terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# --- FASE 1: REDES CORPORATIVAS AISLADAS (VPC) ---
resource "aws_vpc" "vpc_principal" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = { Name = "vpc-sistema-omnichannel" }
}

resource "aws_subnet" "subnet_publica_a" {
  vpc_id            = aws_vpc.vpc_principal.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
  tags = { Name = "subnet-publica-devops-a" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc_principal.id
  tags   = { Name = "igw-sistema" }
}

resource "aws_route_table" "rt_publica" {
  vpc_id = aws_vpc.vpc_principal.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet_publica_a.id
  route_table_id = aws_route_table.rt_publica.id
}

# --- FASE 2: SEGURIDAD PERIMETRAL RESTRICTIVA (HARDENING) ---
resource "aws_security_group" "sg_frontend" {
  name        = "sg_modulo_frontend"
  description = "Permite acceso web HTTP publico"
  vpc_id      = aws_vpc.vpc_principal.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "sg_backends" {
  name        = "sg_modulos_backends"
  description = "Aislamiento: Solo acepta peticiones de la VPC interna"
  vpc_id      = aws_vpc.vpc_principal.id

  ingress {
    from_port   = 8081
    to_port     = 8082
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- FASE 3: ORQUESTACIÓN DE PRODUCCIÓN DE ALTA DISPONIBILIDAD (AMAZON ECS) ---
resource "aws_ecs_cluster" "cluster_produccion" {
  name = "cluster-sistema-produccion"
}

# Definición elástica para la ejecución de tareas de contenedores Fargate
resource "aws_ecs_task_definition" "tarea_ventas" {
  family                   = "back-ventas-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  container_definitions = jsonencode([{
    name      = "back-ventas"
    image     = "nginx:alpine" # Placeholder que el pipeline actualizará dinámicamente con ECR
    essential = true
    portMappings = [{
      containerPort = 8081
      hostPort      = 8081
    }]
  }])
}
