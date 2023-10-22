resource "aws_vpc" "mtc_vpc" {
  cidr_block           = "10.123.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "dev"
  }
}

resource "aws_subnet" "mtc_public_subnet_2a" {
  vpc_id                  = aws_vpc.mtc_vpc.id
  cidr_block              = "10.123.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-2a"

  tags = {
    Name = "dev-public-2a"
  }
}

resource "aws_subnet" "mtc_public_subnet_2b" {
  vpc_id                  = aws_vpc.mtc_vpc.id
  cidr_block              = "10.123.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-2b"

  tags = {
    Name = "dev-public-2b"
  }
}


resource "aws_subnet" "mtc_private_subnet_2a" {
  vpc_id                  = aws_vpc.mtc_vpc.id
  cidr_block              = "10.123.100.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-2a"

  tags = {
    Name = "dev-private-2a"
  }
}

resource "aws_subnet" "mtc_private_subnet_2b" {
  vpc_id                  = aws_vpc.mtc_vpc.id
  cidr_block              = "10.123.101.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-2b"

  tags = {
    Name = "dev-private-2b"
  }
}

resource "aws_internet_gateway" "mtc_internet_gateway" {
  vpc_id = aws_vpc.mtc_vpc.id

  tags = {
    Name = "dev-igw"
  }
}

resource "aws_route_table" "mtc_public_rt" {
  vpc_id = aws_vpc.mtc_vpc.id

  tags = {
    Name = "dev_public_rt"
  }
}

resource "aws_route" "default_route" {
  route_table_id         = aws_route_table.mtc_public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.mtc_internet_gateway.id
}

resource "aws_route_table_association" "mtc_public_2a_assoc" {
  subnet_id      = aws_subnet.mtc_public_subnet_2a.id
  route_table_id = aws_route_table.mtc_public_rt.id
}


resource "aws_route_table_association" "mtc_public_2b_assoc" {
  subnet_id      = aws_subnet.mtc_public_subnet_2b.id
  route_table_id = aws_route_table.mtc_public_rt.id
}

resource "aws_route_table" "mtc_private_rt_a" {
  vpc_id = aws_vpc.mtc_vpc.id

  tags = {
    Name = "dev_private_rt_a"
  }
}

resource "aws_route_table" "mtc_private_rt_b" {
  vpc_id = aws_vpc.mtc_vpc.id

  tags = {
    Name = "dev_private_rt_b"
  }
}


resource "aws_security_group" "mtc_sg" {
  name        = "dev_sg"
  description = "dev security group"
  vpc_id      = aws_vpc.mtc_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
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

resource "aws_key_pair" "mtc_auth" {
  key_name   = "mtckey"
  public_key = file("~/.ssh/mtckey.pub")
}

resource "aws_instance" "mtc_bastion_host_node" {
  instance_type          = "t2.micro"
  ami                    = data.aws_ami.server_ami.id
  key_name               = aws_key_pair.mtc_auth.id
  vpc_security_group_ids = [aws_security_group.mtc_sg.id]
  subnet_id              = aws_subnet.mtc_public_subnet_2a.id
  user_data = file("userdata.tpl")

  root_block_device {
    volume_size = 10
  }

  tags = {
    Name = "bastion-host-node"  
  }

  provisioner "local-exec" { //has to be - not _ for the name
    command = templatefile("${var.host_os}-ssh-config.tpl", {
      hostname = self.public_ip,  // this is the ip of the aws instance
      user = "ubuntu",
      identityFile = "~/.ssh/mtckey" //private key
    })
    interpreter = var.host_os == "windows" ? ["Powershell", "-Command"] : ["bash", "-c"]
  }

}

resource "aws_security_group" "private_mtc_sg" {
  name        = "private_sg"
  description = "private security group"
  vpc_id      = aws_vpc.mtc_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = [
      aws_security_group.mtc_sg.id
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "mtc_private_node" {
  instance_type          = "t2.micro"
  ami                    = data.aws_ami.server_ami.id
  vpc_security_group_ids = [aws_security_group.private_mtc_sg.id]
  subnet_id              = aws_subnet.mtc_private_subnet_2a.id
  
  user_data = file("userdata.tpl")
  
  root_block_device {
    volume_size = 10
  }

  tags = {
    Name = "private-host-node"  
  }
}