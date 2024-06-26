resource "aws_default_subnet" "default_subnet" {
  availability_zone = var.availablity_zone


  tags = var.tags
}
resource "aws_default_subnet" "default_subnet-b" {
  availability_zone = var.availablity_zoneb

  tags = var.tags
}
resource "aws_default_subnet" "default_subnet-c" {
  availability_zone = var.availablity_zonec

  tags = var.tags
}

resource "aws_default_vpc" "default_vpc" {
  tags = var.tags
}

resource "aws_default_security_group" "default" {
  vpc_id = aws_default_vpc.default_vpc.id
  tags   = var.tags
  ingress {
    protocol  = -1
    self      = true
    from_port = 0
    to_port   = 0
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


