#---------  excution role: used by ecs agent  -----------#
#--------- ecs pull from ecr, write to cloudwatch -----------#
//Role: just an container with a trust policy, tells 'who can assume this role'- "the ECS service is allowed to assume this role"
resource "aws_iam_role" "ecs_execution_role" {
    name = "${local.prefix}-ecs-task-excution-role"
    //trust Policy (Who can assume the role)
    assume_role_policy = jsonencode({ //translate tf language into JSON
        Version = "2012-10-17"
        Statement = [
            {   Action = "sts:AssumeRole" //the actual permission being granted: allowed to assume this role
                Effect = "Allow"
                Sid = ""
                Principal = {
                    Service = "ecs.amazonaws.com" //ecs service
                }
            }]
    })
    tags = local.common_tags
}
#attach AWS managed policy, covers ecr pull
#CloudWatch Logs write access is granted by this code as well, just invisibly, bundled inside that one managed policy attachment.
resource "aws_iam_role_policy_attachment" "ecs_excution" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
} //arn = amazon resource name = unique identifier. 
//arn:partition:service:region:account-id:resource
//iam:: region is empty because iam is a global service


#--------- task role -> used by app code at runtime -----------#
#---------  read/write dynamodb only  -----------#
resource "aws_iam_role" "ecs_task" {
    name = "${local.prefix}-ecs-iam-role"
    assume_role_policy = jsonencode(
    {   Version = "2012-10-17"
        Statement = [
            {
                Action = "sts:AssumeRole"
                Effect = "Allow"
                Principal = {
                    Service = "ecs-tasks.amazonaws.com" //ecs
                }
            }]
    })
    tags = local.common_tags
}
#dynomadb permissions as a policy document
data "aws_iam_policy_document" "ecs_task" {
    statement {
        effect = "Allow"
        actions = [
            "dynamodb:GetItem",     # cache miss — read from DB
            "dynamodb:PutItem",     # write new to dynamodb
            # "dynamodb:UpdateItem",  # update click count etc.
            # "dynamodb:Query",       # query by partition key
        ]
        resources = ["*"]  #replace * after specific table is created, to limit the scope of the policy to that table only.
    }
}
#register the policy document as an IAM policy
resource "aws_iam_policy" "ecs_task" {
    name = "${local.prefix}-ecs-task-policy"
    policy = data.aws_iam_policy_document.ecs_task.json
    tags = local.common_tags
}
#attach the custom policy to the role
resource "aws_iam_role_policy_attachment" "ecs_task" {
    role = aws_iam_role.ecs_task.name
    policy_arn = aws_iam_policy.ecs_task.arn //this will look like: 
    //arn:aws:dynamodb:ap-southeast-2:123456789012:table/url-shortener-prod-urls
}











