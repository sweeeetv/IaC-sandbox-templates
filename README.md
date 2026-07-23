## Project 2 Backend URL shortener
### What it does:
basically point a long url to a short combination of 6 random characters.
### Stacks:
Language: Go
IaC: Terraform
Infra: AWS
### Useful scenarios for the Infra:
- Link in bios
- high-read, low-write workload — product pages, content APIs, anything where the same data is read far more than it changes.
### Extras:
- 2 TTLS: 
- - CF (Go app's response headers, shorter) 
- - Redis (Go code, longer)
- Load test with `hey`
```bash
hey -n 100000 -c 200 https://yoursite.com/abc123
# -n = total requests, -c = concurrent users
```
### Notes:
- Cache:
- - CloudFront →  caches the HTTP response at the edge globally
- - Redis →  caches the data lookup inside VPC
- CF protects DynamoDB from repeat traffic. Redis protects DynamoDB from CF misses. Without Redis, every CF miss becomes a DynamoDB read.
- This is a lab from free code camp: 
### Resources:
- Hashicorp/aws: https://registry.terraform.io/providers/hashicorp/aws/latest/docs


```
1. VPC + subnets + internet gateway
2. Security groups
3. IAM roles
4. DynamoDB + ElastiCache
5. ECR (vpc endpoints for the ecs fargate tasks)
6. ECS cluster + task definition + service
7. ALB + target group + listener
8. CloudFront + WAF
9. Route53
10. 
```









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