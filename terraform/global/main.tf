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

################################################################################
# DNS Records: Frontend subdomains → Vercel
################################################################################

resource "aws_route53_record" "frontend_prod" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "app.${var.domain_name}"
  type    = "CNAME"
  ttl     = 300
  records = ["cca28d49e9ec1dae.vercel-dns-017.com."]
}

resource "aws_route53_record" "frontend_dev" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "app-dev.${var.domain_name}"
  type    = "CNAME"
  ttl     = 300
  records = ["cca28d49e9ec1dae.vercel-dns-017.com."]
}
