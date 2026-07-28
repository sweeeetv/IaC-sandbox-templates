//default NACLs -> allow all in, out, no NACLs here
//defautl sg -> all out to *, all in from sg
//custom sg -> all out, no in
//Default NACL/SG can be modified, but should not

#----------------- SG - ALB -------------------#
data "aws_ec2_managed_prefix_list" "cf-prefix"{
    name ="com.amazonaws.global.cloudfront.origin-facing" //get the aws ip listt for cf
}
resource "aws_security_group" "alb" {
    description = "allow inbound https from cf only, outbound to ecs only"
    vpc_id = aws_vpc.main.id
    tags = local.common_tags
    name = "${local.prefix}-alb-sg"
    ingress { //inbound traffics from the internet
        from_port = 80
        to_port = 80 // range from 443 to 443
        protocol = "tcp"
        prefix_list_ids = [data.aws_ec2_managed_prefix_list.cf-prefix.id] //ingress from cloudfront only.  
        # cidr_blocks = [data.aws_ec2_managed_prefix_list.cf-prefix.cidr_blocks[0]] //samilar effect.

        # why http not https:
        # getting a real ACM cert for HTTPS requires a custom domain, ALB's default DNS name (*.elb.amazonaws.com) — AWS doesn't issue public certs for this. no Route53/a custom domain, HTTPS ALB→Cf isn't available. The security model relies on: client↔Cf is HTTPS (real encryption, public-facing), and CF↔ALB is plaintext but confined to AWS's backbone nw and restricted to CF's IP range only via prefix-list SG rule — a standard, accepted patter..
    }
    egress {
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        security_groups = [aws_security_group.ecs.id] //allow outbount to ecs only
    }
}

//second style to write rules:
# resource "aws_vpc_security_group_ingress_rule" "allow_public" {
#     security_group_id = aws_security_group.alb.id
#     cidr_ipv4 = "0.0.0.0/0" // fcc checker
#     ip_protocol = "tcp"
#     to_port = 443
# }

#----------------- SG - ecs -------------------#

# gateway endpoints do not have an ip 10.x, needs prefix list.
data "aws_ec2_managed_prefix_list" "s3" { 
  name = "com.amazonaws.ap-southeast-2.s3"
}
data "aws_ec2_managed_prefix_list" "dynamodb" {
  name = "com.amazonaws.ap-southeast-2.dynamodb"
}

resource "aws_security_group" "ecs" {
    name = "${local.prefix}-ecs-sg"
    vpc_id = aws_vpc.main.id
    description = "inbounds from ALB only, outbound to cache"
    tags = local.common_tags
    # 1:
    # ingress {
    #     from_port = 8080 //app listens at 8080
    #     to_port = 8080 
    #     protocol = "tcp"
    #     security_groups = [aws_security_group.alb.id] //only in from alb
    # }
    egress {
        from_port = 6379
        to_port =  6379
        protocol = "tcp" 
        security_groups=[aws_security_group.cache.id]//to elasti
    }
    egress { //pull from ecr, cloudwatch, dynamodb ep, cache
        from_port = 443 //all use 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["10.0.0.0/16"]
        # VPC endpoint has private ips.
        # gateway ep routes via rt not ip.
    }
}
# 1
resource "aws_vpc_security_group_ingress_rule" "ecs_from_alb" {
  security_group_id = aws_security_group.ecs.id
  from_port          = 8080
  to_port            = 8080
  ip_protocol        = "tcp"
  referenced_security_group_id = aws_security_group.alb.id
}
//pull the image from s3's gateway endpoint 
resource "aws_vpc_security_group_egress_rule" "ecs_to_s3" { 
  security_group_id = aws_security_group.ecs.id
  from_port          = 443
  to_port            = 443
  ip_protocol        = "tcp"
  prefix_list_id     = data.aws_ec2_managed_prefix_list.s3.id
}
//ecs to dynamodb:
resource "aws_vpc_security_group_egress_rule" "ecs_to_dynamodb" {
  security_group_id = aws_security_group.ecs.id
  from_port          = 443
  to_port            = 443
  ip_protocol        = "tcp"
  prefix_list_id     = data.aws_ec2_managed_prefix_list.dynamodb.id
}




#----------------- SG - elastic cache -------------------#
resource "aws_security_group" "cache" {
    name = "${local.prefix}-cache-sg"
    vpc_id = aws_vpc.main.id
    description = "allow inbound redis from ecs only"
    tags = local.common_tags
    # ingress { // from ecs
    #     from_port = 6379 
    #     to_port = 6379 
    #     protocol = "tcp" 
    #     security_groups = [aws_security_group.ecs.id] 
    # }
    //no egress block, never initiate outbound connections by itself
}

resource "aws_vpc_security_group_ingress_rule" "cache_from_ecs" {
  security_group_id            = aws_security_group.cache.id
  from_port                = 6379
  to_port                  = 6379 //port 6379, Redis protocol, not HTTPS
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.ecs.id //inbound from ecs only
}

#----------------- SG for interface endpoints ----------------#
resource "aws_security_group" "vpce" {
    name = "${local.prefix}-vpce-sg"
    vpc_id = aws_vpc.main.id
    description = "allow 443 in from ecs only"
    tags = local.common_tags
    # ingress {
    #     from_port = 443
    #     to_port = 443
    #     protocol = "tcp"
    #     security_groups = [aws_security_group.ecs.id]
    # }
}

resource "aws_vpc_security_group_ingress_rule" "vpce_from_ecs" {
  security_group_id            = aws_security_group.vpce.id
  from_port                = 443
  to_port                  = 443
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.ecs.id //inbound from ecs only
}

