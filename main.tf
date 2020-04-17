################### S3 ######################

# create the bare domain S3 bucket

resource "aws_s3_bucket" "bare-domain" {
  bucket = var.domain
  acl    = "public-read"

  website {
    redirect_all_requests_to = "www.${var.domain}"
  }

  tags = {
    Name = "Managed by Terraform"
  }
}

# create the www bucket - web files are stored here

resource "aws_s3_bucket" "www-domain" {
  bucket = "www.${var.domain}"
  acl    = "public-read"

  website {
    index_document = "index.html"
  }

  tags = {
    Name = "Managed by Terraform"
  }
}

################### Cloudfront ######################

resource "aws_cloudfront_distribution" "www_distribution" {
  origin {
    custom_origin_config {
      http_port              = "80"
      https_port             = "443"
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }

    domain_name = aws_s3_bucket.www-domain.website_endpoint
    origin_id   = "www.${var.domain}"
  }

  enabled             = true
  default_root_object = "index.html"

  default_cache_behavior {
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "www.${var.domain}"
    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  aliases = ["www.${var.domain}"]

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate.cert.arn
    ssl_support_method  = "sni-only"
  }
}

################### Route53 ######################

# hosted zone

resource "aws_route53_zone" "zone" {
  name = var.domain
}

# bare domain

resource "aws_route53_record" "bare-domain" {
  zone_id = aws_route53_zone.zone.zone_id
  name    = var.domain
  type    = "A"

  alias {
    name                   = aws_s3_bucket.bare-domain.website_domain
    zone_id                = aws_s3_bucket.bare-domain.hosted_zone_id
    evaluate_target_health = false
  }
}

# www domain

resource "aws_route53_record" "www-domain" {
  zone_id = aws_route53_zone.zone.zone_id
  name    = "www.${var.domain}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.www_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.www_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}

########################## ACM ########################
resource "aws_acm_certificate" "cert" {
    domain_name               = "*.${var.domain}"
    subject_alternative_names = [
        "${var.domain}",
    ]
    validation_method         = "DNS"

    options {
        certificate_transparency_logging_preference = "ENABLED"
    }
}