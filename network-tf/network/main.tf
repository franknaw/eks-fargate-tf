# Create VPC
resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  instance_tenancy     = "default"
  enable_dns_hostnames = true

  tags = {
    Name                                                                   = "${var.vpc_name}-${terraform.workspace}"
    "kubernetes.io/cluster/${var.eks_cluster_name}-${terraform.workspace}" = "shared"
    Environment                                                            = terraform.workspace
  }
}

data "aws_availability_zones" "all" {
  state         = "available"
  exclude_names = ["us-east-1c", "us-east-1d", "us-east-1e", "us-east-1f"]
}

# Create Public Subnets
resource "aws_subnet" "pub_subnet" {
  count = length(data.aws_availability_zones.all.names)

  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = cidrsubnet(aws_vpc.vpc.cidr_block, 8, count.index)
  availability_zone       = data.aws_availability_zones.all.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name                                                                   = "${terraform.workspace}-public-subnet-${(count.index + 1)}"
    "kubernetes.io/cluster/${var.eks_cluster_name}-${terraform.workspace}" = "shared"
    "kubernetes.io/role/elb"                                               = 1
    Environment                                                            = terraform.workspace
    Tier                                                                   = "public"
  }
}

# Create Private Subnets
resource "aws_subnet" "priv_subnet" {
  count = length(data.aws_availability_zones.all.names)

  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = cidrsubnet(aws_vpc.vpc.cidr_block, 8, count.index + length(data.aws_availability_zones.all.names))
  availability_zone       = data.aws_availability_zones.all.names[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name                                                                   = "${terraform.workspace}-private-subnet-${(count.index + 1)}"
    "kubernetes.io/cluster/${var.eks_cluster_name}-${terraform.workspace}" = "shared"
    "kubernetes.io/role/internal-elb"                                      = 1
    Environment                                                            = terraform.workspace
    Tier                                                                   = "private"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "ig" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "eks-igw-${terraform.workspace}"
  }
}

# Create NAT Gateway
resource "aws_eip" "nat_eip" {
  tags = {
    Name = "eks-nat-eip-${terraform.workspace}"
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.pub_subnet[0].id

  tags = {
    Name = "eks-nat-gw-${terraform.workspace}"
  }
  depends_on = [aws_internet_gateway.ig]
}

# Route Table for Public Subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = var.cidr_block_igw
    gateway_id = aws_internet_gateway.ig.id
  }
  tags = {
    Name = "eks-public-rt-${terraform.workspace}"
  }
}

# Route Table for Private Subnets
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block     = var.cidr_block_igw
    nat_gateway_id = aws_nat_gateway.nat.id
  }
  tags = {
    Name = "eks-private-rt-${terraform.workspace}"
  }
}

resource "aws_route_table_association" "public" {
  count = length(data.aws_availability_zones.all.names)

  subnet_id      = element(aws_subnet.pub_subnet.*.id, count.index)
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count = length(data.aws_availability_zones.all.names)

  subnet_id      = element(aws_subnet.priv_subnet.*.id, count.index)
  route_table_id = aws_route_table.private.id
}

// TODO add this to the helm ALB
resource "aws_security_group" "eks-alb-sg" {
  vpc_id = aws_vpc.vpc.id
  name   = "EKS-ALB-SG"

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = [
    "0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = [
    "0.0.0.0/0"]
  }

  tags = {
    "Name" = "EKS-ALB-SG"
  }
}