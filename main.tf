
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
  key_name   = "deployer-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCvf/Y+KA7PMiqML9NqIKFzBUjkQlpJvO8zuUqOHujhamKG8y6dW2cHViVpUVGWoyOfBZtizdcal1p4Py2CTekudQpGGdJMf/eqVnDzamVDHMc3562Bb0vJp2D46do90q+f05xlJW+lGJIVowA5jEbzJCP8DCmuvZIXiG634ZgEPfJe4bIOZzwzMnkm9m42bGT/Byv/wyj0OI680JdfrKeq51TVgz7hgDltdE4bwzJmACciLMyJPP59wnx1anzjszT0dFHe3pI5RuJ1wcYWGUHPRf78FW2XeIjkL2d4zlq7lD8TNajh2HoUA6/g3D7npehwwC49wgL+TQyyaxGpJ0uUDvb8XOIaWjkZ9UFmGYfFRwW22ATVWNUGK1W+HXTFiA9iMZ4yZPM+gSAlCg9et/ux5GwW58+7NAkP1RRNk7YFPHyotBsXdFFfc/98hPZ03xbUg/sc/VCRHa+uHU55nmBtO9t1qt77VH+c79JQwE/78Uypu7pUiMlb2ammG348mvs= Amol@DESKTOP-2MVQBON"
}

resource "aws_instance" "card01" {
  ami           = "ami-0376ec8eacdf70aae"
  instance_type = "t2.micro"
  key_name = aws_key_pair.deployer.id     #"linux-os-key"
  subnet_id = aws_subnet.card-subnet-1a.id
  vpc_security_group_ids = [aws_security_group.allow_ssh.id,aws_security_group.allow_http.id]
  tags = {
    Name = "card01"
  }
}


resource "aws_instance" "card02" {
  ami           = "ami-0376ec8eacdf70aae"
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
    Name = "allow_http"
  }
}