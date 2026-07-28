# P2 CloudFront, ALB, Fargate, Elasticache, DynamoDB
### What it does:
Points a long url to a short combination of 6 random characters, and save these to a database so clients can redirect back to the long url with the short code. 
### Stacks:
Language: Go
IaC: Terraform
Infra: AWS
### Useful scenarios for the Infra:
- high-read, low-write workload — product pages, content APIs, anything where the same data is read far more than it changes.
### More Infos:
- 2 TTLS: 
    - CF (Go app's response headers, shorter) 
    - Redis (Go code, longer)
- No Cache at CF.
- TF files:
```
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