resource "aws_networkmanager_global_network" "main" {
  description = "Global network for ${var.project_name} enterprise connectivity"

  tags = {
    Name        = "${var.project_name}-global-net"
    Environment = var.environment
  }
}

resource "aws_networkmanager_core_network" "core" {
  global_network_id = aws_networkmanager_global_network.main.id
  description       = "Cloud WAN Core Network"

  tags = {
    Name        = "${var.project_name}-core-net"
    Environment = var.environment
  }
}


data "aws_networkmanager_core_network_policy_document" "core_policy" {
  core_network_configuration {
    asn_ranges = ["64512-64555"]
    edge_locations {
      location = "us-east-1"
      asn      = 64512
    }
    edge_locations {
      location = "eu-west-1"
      asn      = 64513
    }
  }

  segments {
    name                          = "workloads"
    require_attachment_acceptance = false
  }

  segments {
    name                          = "security"
    require_attachment_acceptance = false
  }
}

resource "aws_networkmanager_core_network_policy_attachment" "core_policy_attach" {
  core_network_id = aws_networkmanager_core_network.core.id
  policy_document = data.aws_networkmanager_core_network_policy_document.core_policy.json
}
