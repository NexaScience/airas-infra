module "ecr" {
  source = "../modules/ecr"

  project = var.project
}

################################################################################
# Route 53 Hosted Zone (共有リソース)
################################################################################

resource "aws_route53_zone" "main" {
  name = var.domain_name

  tags = {
    Name      = "${var.project}-zone"
    ManagedBy = "terraform"
  }
}
