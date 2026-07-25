# P2 CloudFront, ALB, Fargate, Elasticache, DynamoDB
### What it does:
basically points a long url to a short combination of 6 random characters.
### Stacks:
Language: Go
IaC: Terraform
Infra: AWS
### Useful scenarios for the Infra:
- high-read, low-write workload — product pages, content APIs, anything where the same data is read far more than it changes.
### More Infos:
- 2 TTLS: 
- - CF (Go app's response headers, shorter) 
- - Redis (Go code, longer)
- No Cache at CF.
- TF files:
    1. VPC + subnets + internet gateway
    2. Security groups
    3. IAM roles
    4. DynamoDB + ElastiCache
    5. ECR (vpc endpoints for the ecs fargate tasks)
    6. ECS cluster + task definition + service
    7. Cloudwatch
    8. ALB + target group + listeners
    8. CloudFront + WAF










```
After networking.tf  → plan + apply
                       actually create the VPC, subnets, IGW, route tables
                       go into AWS console and verify they look right

After security.tf    → plan + apply
                       SGs get created, unassociated is fine
                       console: check each SG's inbound/outbound rules visually

After ecr.tf         → plan + apply
                       push your Go image manually to ECR to verify it works
                       docker build + docker push

After data.tf        → plan + apply
                       verify DynamoDB table exists, ElastiCache cluster is up

After compute.tf     → plan + apply  ← first real integration test
                       ECS task will either start or fail with a stopped reason
                       this is where port/IAM/network issues surface

After alb.tf         → hit the ALB DNS name directly, bypass CF for now
After cdn.tf+dns.tf  → full end to end test

```