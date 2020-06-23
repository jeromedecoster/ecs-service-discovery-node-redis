locals {
  node_container_port = 5000
}

resource aws_ecs_cluster ecs_cluster {
  name = local.project_name
}

resource aws_cloudwatch_log_group log_group {
  name = "${local.project_name}-log-group"
}

resource aws_ecs_task_definition task_redis {
  family = "redis"

  container_definitions = <<DEFINITION
[{
    "name": "redis",
    "image": "redis:alpine",
    "cpu": 0,
    "essential": true,
    "networkMode": "awsvpc",
    "privileged": false,
    "readonlyRootFilesystem": false,
    "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
            "awslogs-group": "${aws_cloudwatch_log_group.log_group.name}",
            "awslogs-region": "${var.region}",
            "awslogs-stream-prefix": "redis"
        }
    }
}]
DEFINITION

  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
}

resource aws_ecs_service service_redis {
  name                = "redis"
  cluster             = aws_ecs_cluster.ecs_cluster.id
  task_definition     = aws_ecs_task_definition.task_redis.arn
  launch_type         = "FARGATE"
  desired_count       = 1
  scheduling_strategy = "REPLICA"

  network_configuration {
    subnets          = [aws_subnet.subnet_1.id, aws_subnet.subnet_2.id]
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = true
  }

  service_registries {
    registry_arn = aws_service_discovery_service.redis.arn
  }
}

resource aws_ecs_task_definition task_node {
  family = "node"

  container_definitions = <<DEFINITION
[{
    "name": "node",
    "image": "jeromedecoster/vote:latest",
    "cpu": 0,
    "essential": true,
    "networkMode": "awsvpc",
    "privileged": false,
    "readonlyRootFilesystem": false,
    "environment": [
        {
            "name": "REDIS_HOST",
            "value": "redis.${local.project_name}"
        }
    ],
    "portMappings": [
      {
        "containerPort": ${local.node_container_port},
        "hostPort": ${local.node_container_port}
      }
    ],
    "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
            "awslogs-group": "${aws_cloudwatch_log_group.log_group.name}",
            "awslogs-region": "${var.region}",
            "awslogs-stream-prefix": "node"
        }
    }
}]
DEFINITION

  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
}

resource aws_ecs_service service_node {
  name                = "node"
  cluster             = aws_ecs_cluster.ecs_cluster.id
  task_definition     = aws_ecs_task_definition.task_node.arn
  launch_type         = "FARGATE"
  desired_count       = var.desired_count
  scheduling_strategy = "REPLICA"

  network_configuration {
    subnets          = [aws_subnet.subnet_1.id, aws_subnet.subnet_2.id]
    security_groups  = [aws_security_group.ecs_tasks.id, aws_security_group.alb.id]
    assign_public_ip = true
  }

  service_registries {
    registry_arn = aws_service_discovery_service.node.arn
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.alb_target_group.arn
    container_name   = "node"
    container_port   = local.node_container_port
  }

  depends_on = [aws_alb_listener.alb_listener]
}
