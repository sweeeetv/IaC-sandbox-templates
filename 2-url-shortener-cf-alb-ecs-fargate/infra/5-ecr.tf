resource "aws_ecr_repository" "app" {
    name = "${local.prefix}-ecr"
    tags = local.common_tags
    image_scanning_configuration {
        scan_on_push = true #scan the image for vulnerabilities when pushed to ECR
  }
}
//<<EOF ... EOF -> Heredoc lets you write raw text between <<EOF and a closing EOF, and Terraform treats everything in between as a string — no escaping needed. 
resource "aws_ecr_lifecycle_policy" "app" {
  repository = aws_ecr_repository.app.name
    policy = <<EOF
    {
"rules": [
    {
    "rulePriority": 1,
    "description": "Expire images older than 14 days",
    "selection": {
        "tagStatus": "untagged",
        "countType": "sinceImagePushed",
        "countUnit": "days",
        "countNumber": 14
    },
    "action": {
        "type": "expire"
    }
    }
]
}
EOF
}
//"tagStatus": "untagged" -> only cleans up the untagged orphon images.
//Tagged images (e.g. latest, v1) are kept forever
# if use azure ACR:
#-----------------------------------------------------------#
# container_definitions = jsonencode([{
#   name  = "url-shortener"
#   image = "yourregistry.azurecr.io/url-shortener:latest"
  
#   repositoryCredentials = {
#     credentialsParameter = aws_secretsmanager_secret.acr_creds.arn
#   }
# }])