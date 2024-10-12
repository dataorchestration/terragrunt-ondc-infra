terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "5.34.0"
    }
  }
}


resource "google_compute_security_policy" "policy" {
  name        = var.security_policy_name
  description = "Enhanced security policy for load balancer protection"
  project     = var.project_id
  type        = "CLOUD_ARMOR"
  adaptive_protection_config {
    layer_7_ddos_defense_config {
      enable          = true
      rule_visibility = "STANDARD"
    }
  }
  # Rule 1: Rate limiting - 1000 requests per minute per IP
  rule {
    action   = "rate_based_ban"
    priority = "1000"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    rate_limit_options {
      rate_limit_threshold {
        count        = 1000
        interval_sec = 60
      }
      ban_duration_sec = 600  # Ban for 10 minutes if limit exceeded
      conform_action = "allow"
      exceed_action  = "deny(429)"
    }
    description = "Rate limit: 1000 requests per minute per IP"
  }

  # Rule 2: Allow traffic only from India
  rule {
    action   = "allow"
    priority = "2000"
    match {
      expr {
        expression = "origin.region_code == 'IN'"
      }
    }
    description = "Allow traffic only from India"
  }

  # Rule 3: XSS Protection
  rule {
    action   = "deny(403)"
    priority = "3000"
    match {
      expr {
        expression = "evaluatePreconfiguredExpr('xss-stable')"
      }
    }
    description = "XSS Protection"
  }

  # Rule 4: SQL Injection Protection
  rule {
    action   = "deny(403)"
    priority = "4000"
    match {
      expr {
        expression = "evaluatePreconfiguredExpr('sqli-stable')"
      }
    }
    description = "SQL Injection Protection"
  }

  # Rule 5: Remote File Inclusion Protection
  rule {
    action   = "deny(403)"
    priority = "5000"
    match {
      expr {
        expression = "evaluatePreconfiguredExpr('rfi-stable')"
      }
    }
    description = "Remote File Inclusion Protection"
  }

  # Rule 6: Local File Inclusion Protection
  rule {
    action   = "deny(403)"
    priority = "6000"
    match {
      expr {
        expression = "evaluatePreconfiguredExpr('lfi-stable')"
      }
    }
    description = "Local File Inclusion Protection"
  }

  # Rule 7: Command Injection Protection
  # rule {
  #   action   = "deny(403)"
  #   priority = "7000"
  #   match {
  #     expr {
  #       expression = "evaluatePreconfiguredExpr('commandinjection-stable')"
  #     }
  #   }
  #   description = "Command Injection Protection"
  # }

  # Rule 8: Custom Request Header Requirement

  # Rule 9: Default deny all other traffic
  rule {
    action   = "deny(403)"
    priority = "2147483647"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    description = "Default deny rule"
  }

  # Enable threat intelligence and other advanced options
  advanced_options_config {
    json_parsing = "STANDARD"
    log_level    = "VERBOSE"
  }
}

