//vpc, subnet, endpoints

data "aws_availability_zones" "available" {
    state = "available"
} //returns a list of all the availability zones in the region that are currently available. 

resource "aws_vpc" "main" {
    cidr_block = "10.0.0.0/16"
    tags = local.common_tags

    
    enable_dns_support = true //required for DNS resolution of AWS services within the VPC. It allows instances in the VPC to resolve public DNS hostnames to private IP addresses.
    enable_dns_hostnames = true //required for instances in the VPC to have DNS hostnames. It allows instances to be reachable by their DNS names within the VPC.
}

//subnets
resource "aws_subnet" "public-subnet" {
    count = 2 //2 subnets of these natures 
    vpc_id = aws_vpc.main.id
    //cidrsubnet() is a built-in tf function
    cidr_block = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)//(prefix, newbits, netnum) -> newbits = 8 means the subnet mask for this sn is 16+8
    availability_zone = data.aws_availability_zones.available.names[count.index] //.names gives ["ap-southeast-2a", "ap-southeast-2b", "ap-southeast-2c"]
    map_public_ip_on_launch = true //instances will be given pubip when launch.
    tags = merge(
        local.common_tags,
        {//name -> uses UPPER CASE here, so aws can show a readable name in the console.
            Name = "public-subnet-${count.index}" # 0 or 1
        }
    )
}


resource "aws_subnet" "private-subnet" {
    count = 2 
    vpc_id = aws_vpc.main.id
    cidr_block = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index+10)
    availability_zone = data.aws_availability_zones.available.names[count.index] // 0 or 1st position of the names list
    tags = merge (
        local.common_tags,
        {
            Name = "private-subnet-${count.index}"
        }
    )
}

resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.main.id
    tags = local.common_tags
}

#----------------- public route table -------------------#
resource "aws_route_table" "public-rt" { //rts are VPC-scoped then associated to subnets. If a sn is not associated to a rt, it falls back to VPC's main rt.
    vpc_id = aws_vpc.main.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw.id
    }
}
resource "aws_route_table_association" "public" {
    count = 2 //2 accociation resources.
    subnet_id = aws_subnet.public-subnet[count.index].id
    route_table_id = aws_route_table.public-rt.id
}




#----------------- private route table -------------------#
resource "aws_route_table" "private-rt" {
    vpc_id = aws_vpc.main.id
    tags = local.common_tags
}

resource "aws_route_table_association" "private" {
    count = 2
    subnet_id = aws_subnet.private-subnet[count.index].id
    route_table_id = aws_route_table.private-rt.id
}

#----------------- gateway endpoints (free) -------------------#
resource "aws_vpc_endpoint" "s3" {
    vpc_id = aws_vpc.main.id
    service_name = "com.amazonaws.ap-southeast-2.s3" // ECR pulls image layers from S3
    vpc_endpoint_type = "Gateway"
    route_table_ids = [aws_route_table.private-rt.id]
    tags = local.common_tags
}

resource "aws_vpc_endpoint" "dynamodb" {
    vpc_id = aws_vpc.main.id
    service_name = "com.amazonaws.ap-southeast-2.dynamodb"
    vpc_endpoint_type = "Gateway"
    route_table_ids = [aws_route_table.private-rt.id]
    tags = local.common_tags
}

#------ interface eps (hourly cost, ENI per subnet) ------#
# ecr-api is tthe ecr control plane, ecr-dkr is the data plane. ecs agent needs both to pull images from ecr. -  authenticate via ecr-api, then fetch the image via ecr-dkr.
#Layer blobs themselves are stored in S3, which is why s3 gw ep is also needed.
resource "aws_vpc_endpoint" "ecr-api" {
    vpc_id = aws_vpc.main.id
    service_name = "com.amazonaws.ap-southeast-2.ecr.api"
    vpc_endpoint_type = "Interface"
    subnet_ids = aws_subnet.private-subnet[*].id
    security_group_ids = [aws_security_group.vpce.id]
    private_dns_enabled = true //means the endpoint will resolve to the private ip of the ENI in the subnet, instead of the public ip of the service.
    
    tags = local.common_tags
}

resource "aws_vpc_endpoint" "ecr-dkr" {
    vpc_id = aws_vpc.main.id
    service_name = "com.amazonaws.ap-southeast-2.ecr.dkr"
    vpc_endpoint_type = "Interface"
    subnet_ids = aws_subnet.private-subnet[*].id
    security_group_ids = [aws_security_group.vpce.id]
    private_dns_enabled = true
    tags = local.common_tags
}

resource "aws_vpc_endpoint" "logs" {
    vpc_id = aws_vpc.main.id
    service_name = "com.amazonaws.ap-southeast-2.logs"
    vpc_endpoint_type = "Interface"
    subnet_ids = aws_subnet.private-subnet[*].id
    security_group_ids = [aws_security_group.vpce.id]
    private_dns_enabled = true
    tags = local.common_tags
}