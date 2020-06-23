resource aws_alb alb {
  name               = local.project_name
  load_balancer_type = "application"
  subnets            = [aws_subnet.subnet_1.id, aws_subnet.subnet_2.id]
  security_groups    = [aws_security_group.alb.id]

  tags = {
    Name = local.project_name
  }
}

resource aws_alb_target_group alb_target_group {
  name        = local.project_name
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.vpc.id
  target_type = "ip"
}

resource aws_alb_listener alb_listener {
  load_balancer_arn = aws_alb.alb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    target_group_arn = aws_alb_target_group.alb_target_group.arn
    type             = "forward"
  }
}