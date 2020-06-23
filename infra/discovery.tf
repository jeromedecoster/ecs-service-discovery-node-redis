resource aws_service_discovery_private_dns_namespace dns_namespace {
  name = local.project_name
  vpc  = aws_vpc.vpc.id
}

resource aws_service_discovery_service redis {
  name = "redis"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.dns_namespace.id

    dns_records {
      ttl  = 60
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}

resource aws_service_discovery_service node {
  name = "node"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.dns_namespace.id

    dns_records {
      ttl  = 60
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}