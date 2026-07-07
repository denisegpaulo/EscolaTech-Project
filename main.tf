# Data source para buscar a AMI mais recente do Amazon Linux 2023
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# 1. Cria a IAM Role que a EC2 vai assumir
resource "aws_iam_role" "ec2_read_only_role" {
  name = "ec2-web-app-read-only-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# 2. Anexa a política nativa da AWS de ReadOnly para o Auto Scaling e EC2
resource "aws_iam_role_policy_attachment" "asg_read_only" {
  role       = aws_iam_role.ec2_read_only_role.name
  policy_arn = "arn:aws:iam::aws:policy/AutoScalingReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "ec2_read_only" {
  role       = aws_iam_role.ec2_read_only_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
}

# 3. Cria o Instance Profile que serve de "ponte" entre a Role e a EC2
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-web-app-instance-profile"
  role = aws_iam_role.ec2_read_only_role.name
}

provider "aws" {
  region = "us-east-1" # Altere para a região que preferir
}

# ==========================================
# 1. CRIAR VPC
# ==========================================
resource "aws_vpc" "horus_tech" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "horus-tech-vpc"
  }
}

# ==========================================
# 2. CRIAR AS 4 SUBNETS (2 Públicas, 2 Privadas)
# ==========================================

# Subnet Pública 1A
resource "aws_subnet" "public_1a" {
  vpc_id                  = aws_vpc.horus_tech.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true # Habilita IPv4 público automático

  tags = {
    Name = "public-subnet-1a"
  }
}

# Subnet Pública 1B
resource "aws_subnet" "public_1b" {
  vpc_id                  = aws_vpc.horus_tech.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true # Habilita IPv4 público automático

  tags = {
    Name = "public-subnet-1b"
  }
}

# Subnet Privada 1A
resource "aws_subnet" "private_1a" {
  vpc_id            = aws_vpc.horus_tech.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "private-subnet-1a"
  }
}

# Subnet Privada 1B
resource "aws_subnet" "private_1b" {
  vpc_id            = aws_vpc.horus_tech.id
  cidr_block        = "10.0.12.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "private-subnet-1b"
  }
}

# ==========================================
# 3. INTERNET GATEWAY
# ==========================================
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.horus_tech.id # Faz o Attach automático na VPC

  tags = {
    Name = "horus-tech-igw"
  }
}

# ==========================================
# 4. ROUTE TABLE PÚBLICA & ROTAS
# ==========================================
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.horus_tech.id

  # Rota padrão para a Internet apontando para o IGW
  # Nota: A rota interna "10.0.0.0/16 -> local" é criada implicitamente pela AWS
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "rt-public"
  }
}

# ==========================================
# 5. ASSOCIAÇÃO DAS SUBNETS PÚBLICAS
# ==========================================

# Associa Public Subnet 1A à rt-public
resource "aws_route_table_association" "public_1a_assoc" {
  subnet_id      = aws_subnet.public_1a.id
  route_table_id = aws_route_table.public_rt.id
}

# Associa Public Subnet 1B à rt-public
resource "aws_route_table_association" "public_1b_assoc" {
  subnet_id      = aws_subnet.public_1b.id
  route_table_id = aws_route_table.public_rt.id
}

# ==========================================
# 6. ELASTIC IP & NAT GATEWAY
# ==========================================
resource "aws_eip" "nat_eip" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.igw]

  tags = {
    Name = "horus-tech-nat-eip"
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_1a.id # Garante que está na subnet pública com acesso ao IGW

  tags = {
    Name = "horus-tech-nat-gw"
  }

  depends_on = [aws_internet_gateway.igw]
}

# ==========================================
# 7. ROUTE TABLE PRIVADA (AQUI ESTÁ A CORREÇÃO)
# ==========================================
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.horus_tech.id

  # Rota que força todo o tráfego de saída das subnets privadas a passar pelo NAT Gateway
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "rt-private"
  }
}

# ==========================================
# 8. ASSOCIAÇÃO EXPLICITA DAS SUBNETS PRIVADAS
# ==========================================
resource "aws_route_table_association" "private_1a_assoc" {
  subnet_id      = aws_subnet.private_1a.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_1b_assoc" {
  subnet_id      = aws_subnet.private_1b.id
  route_table_id = aws_route_table.private_rt.id
}

# ==========================================
# 9. SECURITY GROUP - ALB (SG-ALB)
# ==========================================
resource "aws_security_group" "sg_alb" {
  name        = "SG-ALB"
  description = "Permitir trafego HTTP/HTTPS externo para o Load Balancer"
  vpc_id      = aws_vpc.horus_tech.id

  # Entrada HTTP (Porta 80) vinda de qualquer lugar da internet
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Entrada HTTPS (Porta 443) vinda de qualquer lugar da internet
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Saída liberada para qualquer destino
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "SG-ALB"
  }
}

# ==========================================
# 10. SECURITY GROUP - EC2 (SG-EC2)
# ==========================================
resource "aws_security_group" "sg_ec2" {
  name        = "SG-EC2"
  description = "Permitir HTTP vindo apenas do ALB e SSH vindo apenas do Meu IP"
  vpc_id      = aws_vpc.horus_tech.id

  # Entrada HTTP (Porta 80) restrita: APENAS tráfego vindo do SG-ALB
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_alb.id]
  }

  # Entrada SSH (Porta 22) restrita ao seu IP de administração
  # DICA: Altere o "0.0.0.0/0" abaixo para o seu IP real (ex: "200.50.10.20/32") se quiser travar o acesso
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Saída liberada para qualquer destino (Essencial para o comando dnf/yum funcionar nas EC2 privadas!)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "SG-EC2"
  }
}

# ==========================================
# 11. APPLICATION LOAD BALANCER (ALB)
# ==========================================
resource "aws_lb" "web_alb" {
  name               = "WebServerELB"
  internal           = false # internet-facing
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg_alb.id]
  subnets            = [aws_subnet.public_1a.id, aws_subnet.public_1b.id] # 2 Subnets públicas

  tags = {
    Name = "WebServerELB"
  }
}

# ==========================================
# 12. TARGET GROUP (GRUPO DE DESTINO)
# ==========================================
resource "aws_lb_target_group" "web_tg" {
  name     = "webserver-app"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.horus_tech.id

  # Configuração exata do seu Health Check apontando para /index.php
  health_check {
    path                = "/index.php"
    protocol            = "HTTP"
    port                = "80"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "webserver-app"
  }
}

# ==========================================
# 13. ALB LISTENER (OUVINTE PORTA 80)
# ==========================================
resource "aws_lb_listener" "web_listener" {
  load_balancer_arn = aws_lb.web_alb.arn
  port              = "80"
  protocol          = "HTTP"

  # Action: Encaminhar o tráfego para o Target Group webserver-app
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}

# ==========================================
# 14. LAUNCH TEMPLATE (MODELO DE INSTÂNCIA)
# ==========================================
resource "aws_launch_template" "web_app" {
  name_prefix   = "web-app-launch-template"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"

  # ADICIONE ESTA LINHA AQUI:
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  vpc_security_group_ids = [aws_security_group.sg_ec2.id]

  user_data = base64encode(templatefile("${path.module}/userdata.sh", {
    asg_name = "horus-tech-asg"        # <-- ESCREVA O NOME EM TEXTO DIRETAMENTE AQUI
    alb_dns  = aws_lb.web_alb.dns_name # Esse pode continuar, pois o ALB não depende do Launch Template!
    logo_url = "https://i.imgur.com/JDLjQCb.png"
  }))


  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "web-app-instance"
      Project     = "TCC-EscolaTech"
      Environment = "Lab"
      ManagedBy   = "Terraform"
    }
  }
}

# ==========================================
# 15. AUTO SCALING GROUP (ASG)
# ==========================================
resource "aws_autoscaling_group" "web_asg" {
  name                = "horus-tech-asg"
  vpc_zone_identifier = [aws_subnet.private_1a.id, aws_subnet.private_1b.id] # Marcando as 2 subnets PRIVADAS
  target_group_arns   = [aws_lb_target_group.web_tg.arn]                     # Registra automaticamente no target group

  # Group Size: Desired = 2 / Min = 2 / Max = 4
  desired_capacity = 2
  min_size         = 2
  max_size         = 6

  launch_template {
    id      = aws_launch_template.web_app.id
    version = "$Latest"
  }

  health_check_type         = "ELB" # Healthcheck do tipo ELB
  health_check_grace_period = 180

  lifecycle {
    create_before_destroy = true

    ignore_changes = [
      desired_capacity # Ignora mudanças no desired_capacity para não destruir a ASG quando o Terraform for aplicado
    ]
  }
}

# ==========================================
# 16. POLÍTICA DE ESCALONAMENTO (TARGET TRACKING)
# ==========================================
resource "aws_autoscaling_policy" "cpu_scaling_policy" {
  name                   = "escola-tech-cpu-tracking"
  autoscaling_group_name = aws_autoscaling_group.web_asg.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    # Metric type: Average CPU utilization
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    # Target value: 40%
    target_value = 40.0
  }
}

# ==========================================
# 17. OUTPUT (Anotar o DNS do Load Balancer)
# ==========================================
output "load_balancer_dns" {
  value       = aws_lb.web_alb.dns_name
  description = "Anotar este DNS. Use esta URL no seu script de ataque para testar o TCC"
}