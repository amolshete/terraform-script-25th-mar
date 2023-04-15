
# VPC creation
resource "aws_vpc" "card_vpc" {
  cidr_block       = "10.10.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "Card_VPC"
  }
}

# subnet config
resource "aws_subnet" "card-subnet-1a" {
  vpc_id     = aws_vpc.card_vpc.id
  cidr_block = "10.10.0.0/24"
  availability_zone = "ap-south-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "card-subnet-1a"
  }
}


resource "aws_subnet" "card-subnet-1b" {
  vpc_id     = aws_vpc.card_vpc.id
  cidr_block = "10.10.1.0/24"
  availability_zone = "ap-south-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "card-subnet-1b"
  }
}


resource "aws_subnet" "card-subnet-1c" {
  vpc_id     = aws_vpc.card_vpc.id
  cidr_block = "10.10.2.0/24"
  availability_zone = "ap-south-1c"
  
  tags = {
    Name = "card-subnet-1c"
  }
}


resource "aws_key_pair" "deployer" {
  key_name   = "webapp"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDM0Fqft1CpqlHV6z6rEqKDr0uIWDaBNu/ftS74G9kwnBKXieqOtlIUVtnrJlffze7gBfIT6QJHqfV8G2zGHXipTKTXX+M5FDWeA0IEWU/DE2LKNfZVdR2Y211BYAkxlB1P/zXy1Eo8oPc9cShUk2d/j2cehs7mGpSZQ8cQM5UIZM6Or+NdTIvv+yxUgOm/xDFd5sWMnW/8hjAeAGYh7ndejvujzq+bXg5I8cigpzYe/izmQMdMP3B3U5BDaO+1IABXeaSbzIw1P1ieURWOhOS3JIyA3rt/D/PNrfVHtq5xOmJIpNRg1qHDLp1Deh0LF5y+sFzOWAdHRE08QM/P7lSwBnswP+/Q5RI0k+ouYEcHjePxTdYCEv1AJ92xk11YrYBDOd0qt8HX7oHzpgfEZPYGQWiIVjuhxirPOa0MZrFY0tG4Kbwsw5zT8IqFKK6O4S5Eb8KH+HoB9JhTIuhg4IalKu8Oa71H98D6F21d03ole+C6tJCRPr18k8xT1qa3mI0= Amol@DESKTOP-2MVQBON"
}

resource "aws_instance" "card01" {
  ami           = "ami-0ad37e9b1d9b2b4c6"
  instance_type = "t2.micro"
  key_name = aws_key_pair.deployer.id     #"linux-os-key"
  subnet_id = aws_subnet.card-subnet-1a.id
  vpc_security_group_ids = [aws_security_group.allow_ssh.id,aws_security_group.allow_http.id]
  tags = {
    Name = "card01"
  }
}


resource "aws_instance" "card02" {
  ami           = "ami-0ad37e9b1d9b2b4c6"
  instance_type = "t2.micro"
  key_name = aws_key_pair.deployer.id     #"linux-os-key"
  subnet_id = aws_subnet.card-subnet-1b.id
  vpc_security_group_ids = [aws_security_group.allow_ssh.id,aws_security_group.allow_http.id]
  tags = {
    Name = "card02"
  }
}

# IG
resource "aws_internet_gateway" "card-IG" {
  vpc_id = aws_vpc.card_vpc.id

  tags = {
    Name = "card-IG"
  }
}

#Route Table

resource "aws_route_table" "card_RT_Public" {
  vpc_id = aws_vpc.card_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.card-IG.id
  }

  tags = {
    Name = "card_RT_Public"
  }
} 

resource "aws_route_table_association" "card_RT_ASSO_Public-1" {
  subnet_id      = aws_subnet.card-subnet-1a.id
  route_table_id = aws_route_table.card_RT_Public.id
}

resource "aws_route_table_association" "card_RT_ASSO_Public-2" {
  subnet_id      = aws_subnet.card-subnet-1b.id
  route_table_id = aws_route_table.card_RT_Public.id
}

# Security Group

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.card_vpc.id

  ingress {
    description      = "SSH from my laptop"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

   ingress {
    description      = "SSH from my laptop"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_ssh"
  }
}


resource "aws_security_group" "allow_http" {
  name        = "allow_http"
  description = "Allow hhtp inbound traffic"
  vpc_id      = aws_vpc.card_vpc.id

 
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_http"
  }
}


# Config for target group
resource "aws_lb_target_group" "card_target_group" {
  name     = "Card-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.card_vpc.id
}

# if we have done instance manually(not with ASG) in that case you have to attached instances to TG manually
resource "aws_lb_target_group_attachment" "card-target-group-attachment-01" {
  target_group_arn = aws_lb_target_group.card_target_group.arn
  target_id        = aws_instance.card01.id
  port             = 80
}


resource "aws_lb_target_group_attachment" "card-target-group-attachment-02" {
  target_group_arn = aws_lb_target_group.card_target_group.arn
  target_id        = aws_instance.card02.id
  port             = 80
}


# Listner for TG

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.card-LB.arn
  port              = "80"
  protocol          = "HTTP"
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.card_target_group.arn
  }
}


# Load balancer

resource "aws_lb" "card-LB" {
  name               = "Card-LB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.allow_ssh.id]
  subnets            = [aws_subnet.card-subnet-1a.id, aws_subnet.card-subnet-1b.id]

  #enable_deletion_protection = true

  tags = {
    Environment = "production"
  }
}


# launch Template

resource "aws_launch_template" "card-launch-template" {
  name = "card-launch-template"
  image_id = "ami-0ad37e9b1d9b2b4c6"
  instance_type = "t2.medium"
  key_name = aws_key_pair.deployer.id
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "card-webapp"
    }
  }
  user_data = filebase64("example.sh")
}


## ASG with ALB

resource "aws_autoscaling_group" "card-ASG" {
  name                      = "card-ASG"
  max_size                  = 5
  min_size                  = 2
  #health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = 2
  vpc_zone_identifier       = [aws_subnet.card-subnet-1a.id, aws_subnet.card-subnet-1b.id]

  launch_template {
    id      = aws_launch_template.card-launch-template.id
    version = "$Latest"
  }
  target_group_arns = [aws_lb_target_group.card-TG-2.arn]
}

# config for target group with ASG

resource "aws_lb_target_group" "card-TG-2" {
  name     = "card-TG-2"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.card_vpc.id
}

#config for listener along with ASG ALB

resource "aws_lb_listener" "card-listener-2" {
  load_balancer_arn = aws_lb.card-LB-2.arn
  port              = "80"
  protocol          = "HTTP"
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.card-TG-2.arn
  }
}


# LB with ASG

resource "aws_lb" "card-LB-2" {
  name               = "card-LB-2"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.allow_ssh.id]
  subnets            = [aws_subnet.card-subnet-1a.id, aws_subnet.card-subnet-1b.id]

  #enable_deletion_protection = true

  tags = {
    Environment = "production"
  }
}