//fargate: a serverless engine/managed container. it's cheaper than ec2, but slower to start. similar to azure container instances (ACI).
//logical grouping, only logically exist, group the tasks for the app together.
resource "aws_ecs_cluster" "app" { //namespace
    name = "${local.prefix}-ecs-cluster"
    setting {
        name = "containerInsights" //this is for cloudwatch monitoring and logging. container insights is a feature of cloudwatch.
        value = "enabled" //enable container insights for monitoring and logging
    }
}

//tell fargate which image to pull from ecr. other configurations
//blueprints for the container, usually 1 task = 1 container/(app)
//important but just a blueprint
# task is a running instance of task definition, task is what actually launches containers.
# one task can hold multiple containers.
# 1 App = 1 Task: bestt. One Definition should generally govern one main Container.

resource "aws_ecs_task_definition" "app" {
    family = "${local.prefix}-ecs-task-def"
    # if each task will have its own ENI / ip in awsvpc mode
    network_mode = "awsvpc" //required for fargate, gets own eni for each task, and can be placed in private subnets. ENI with its own IP, no port translation needed at the host level.
    requires_compatibilities = ["FARGATE"] //fargate launch type, it also has types of: EC2, EXTERNAL (for on-premise)
    cpu = "256" //task cpu, 0.25 vCPU, cheapest
    memory = "512" //task ram

    #iam roles
    execution_role_arn = aws_iam_role.ecs_execution_role.arn//ecs agent role, ecr pull and cloudwatch write
    task_role_arn = aws_iam_role.ecs_task.arn //ecs task role, read/write dynamodb only   

    container_definitions = jsonencode([{
        name  = "${local.prefix}-task-def"
        image = "${aws_ecr_repository.app.repository_url}:latest" //this is for ecs agent to pull the image from ecr.
        //for prod, pass the exact version, not latest.
        essential = true //false -> ecs agent will not stop the task if this container fails, true -> ecs agent will stop the task if this container fails.
        portMappings = [{
            containerPort = 8080
            hostPort      = 8080 
            protocol      = "tcp"
        }]
        environment = [
            {
                name  = "DYNAMO_TABLE"
                value = aws_dynamodb_table.urls.name
            },
            {
                name  = "REDIS_ADDR"
                value = "${aws_elasticache_serverless_cache.redis.endpoint[0].address}:${aws_elasticache_serverless_cache.redis.endpoint[0].port}"
            }
        ]
        logConfiguration = { //send logs to cloudwatch for debugging.
            logDriver = "awslogs" //logs will be sent to cloudwatch logs, not to stdout or stderr.
            options = {
                "awslogs-group"   = aws_cloudwatch_log_group.app.name
                "awslogs-region"        = var.location
                "awslogs-stream-prefix" = "${local.prefix}-ecs"
            }
        }
    }])
}

//manager, scheduler, control plane
# AWS handles Fargate; Service handles the Tasks.
resource "aws_ecs_service" "app" { //registers/deregisters task IPs into the alb target group 
    name = "${local.prefix}-ecs-service"
    cluster = aws_ecs_cluster.app.id
    task_definition = aws_ecs_task_definition.app.arn
    desired_count = 2 # 2 tasks running / containers / private IPs. 
    # each registered as a separate target in ALB target group
    # HA, add ignore_changes if auto-scaling is needed later. -> Scaling to 3 means ECS launches a 3rd task, gets a 3rd ENI/IP, registers it with the ALB automatically.
    launch_type = "FARGATE"
    depends_on = [aws_lb_listener.fargate_app] //listener needs to be ready

    #network
    network_configuration {
        subnets = aws_subnet.private-subnet[*].id //place the task in private subnets. ENI will be created in the private subnet.
        security_groups = [aws_security_group.ecs.id]
        assign_public_ip = false # best practise
    }
    load_balancer {
        //Connects Fargate tasks to public-facing alb
        target_group_arn = aws_lb_target_group.fargate_app.arn
        container_name = "${local.prefix}-task-def" //this is the name of the container in the task definition, not the task definition itself.
        container_port =8080 //match the app
    }
}


# ----------------- hierarchy ----------------- #
# ECS cluster (namespace) - virtual folder, groups tasks and services
# → Service (keeps N tasks running, wires to ALB) - manager / sheduler
#  → Task - a living instance of Task Definition (the blueprint)
#   → Container(s) (actual app) - Usually, 1 Task = 1 Container.
#    → runs ON Fargate (the actual CPU/RAM, serverless compute layer)