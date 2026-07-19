//Internet → ALB:443 (TLS terminates here), or http at 80 → Target Group:8080 (just a point / registry) → Task ENI:8080 → Container:8080
//the container's process is listening directly on the ENI itself, at the port
resource "aws_lb" "fargate_app" {
    name = "${local.prefix}-alb"
    internal = false // in public subnet
    load_balancer_type = "application" 
    security_groups = [aws_security_group.alb.id]
    subnets = [for subnet in aws_subnet.public-subnet : subnet.id] //this will create a list of the public subnet ids, and pass it to the alb resource.
    enable_deletion_protection = false //true will block terraform destroy

    tags = local.common_tags
}

resource "aws_lb_target_group" "fargate_app" { // basically a pointer to the tasks or ecs service.
//holds a dynamic list of registered ips / from the running tasks
    name = "${local.prefix}-alb-tg"
    target_type = "ip" //not "alb" (rare only for alb chaining), as fargate with awsvpc mode registers by ip
    port = 8080 //matches the container port, not a port itself, basically a pointer / registry entry to the real port on the task eni (host).
    protocol = "HTTP" //alb to ecs is http, tls terminates at alb 
    vpc_id = aws_vpc.main.id
    health_check {
        path          = "/health"
        protocol      = "HTTP"
        port          = "traffic-port"# special AWS keyword = use whatever port the TG is configured with
        matcher       = "200"#expect 200 from /health endpoint
        healthy_threshold   = 2
        unhealthy_threshold = 3
        interval            = 30
        timeout             = 10 # timeout must be < internal
    }
}

resource "aws_lb_listener" "fargate_app" {
    load_balancer_arn = aws_lb.fargate_app.arn
    protocol = "HTTP"
    port = 80
    //if protocol = "HTTPS":
    # port = 443
    # ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
    # certificate_arn   = "arn:aws:iam::187416307283:server-certificate/test_cert_rab3wuqwgja25ct3n4jdj2tzu4"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.fargate_app.arn
  }
}