data "aws_connect_security_profile" "this" {
  for_each = { for key, value in var.connect_users : key => value }

  instance_id = aws_connect_instance.this.id
  name        = each.value.security_profile
}

resource "aws_connect_contact_flow" "this" {
  instance_id = aws_connect_instance.this.id
  name        = var.environment
  description = "${replace(var.environment, "_", " ")} automated contact flow triggered by lambda"
  type        = "CONTACT_FLOW"
  content     = file("${path.module}/contact_flow/get_me_out_of_here.json")

  tags = var.tags
}
resource "aws_connect_hours_of_operation" "this" {
  instance_id = aws_connect_instance.this.id
  name        = "24/7 Office Hours"
  description = "24/7 availability"
  time_zone   = "EST"

  config {
    day = "MONDAY"

    start_time {
      hours   = 0
      minutes = 0
    }

    end_time {
      hours   = 23
      minutes = 59
    }
  }

  config {
    day = "TUESDAY"

    start_time {
      hours   = 0
      minutes = 0
    }

    end_time {
      hours   = 23
      minutes = 59
    }
  }

  config {
    day = "WEDNESDAY"

    start_time {
      hours   = 0
      minutes = 0
    }

    end_time {
      hours   = 23
      minutes = 59
    }
  }

  config {
    day = "THURSDAY"

    start_time {
      hours   = 0
      minutes = 0
    }

    end_time {
      hours   = 23
      minutes = 59
    }
  }

  config {
    day = "FRIDAY"

    start_time {
      hours   = 0
      minutes = 0
    }

    end_time {
      hours   = 23
      minutes = 59
    }
  }

  config {
    day = "SATURDAY"

    start_time {
      hours   = 0
      minutes = 0
    }

    end_time {
      hours   = 23
      minutes = 59
    }
  }

  config {
    day = "SUNDAY"

    start_time {
      hours   = 0
      minutes = 0
    }

    end_time {
      hours   = 23
      minutes = 59
    }
  }

  tags = var.tags
}

resource "aws_connect_instance" "this" {
  instance_alias = local.environment

  contact_flow_logs_enabled = true
  identity_management_type  = "CONNECT_MANAGED"
  inbound_calls_enabled     = false
  outbound_calls_enabled    = true
}

resource "aws_connect_phone_number" "this" {
  target_arn   = aws_connect_instance.this.arn
  country_code = var.did_country_code
  type         = "DID"
  prefix       = var.did_prefix

  tags = var.tags
}

resource "aws_connect_queue" "this" {
  instance_id           = aws_connect_instance.this.id
  name                  = local.environment
  description           = "${replace(var.environment, "_", " ")} queue for all users"
  hours_of_operation_id = element(split(":", aws_connect_hours_of_operation.this.id), 1)

  outbound_caller_config {
    outbound_caller_id_name      = "El Jefe"
    outbound_caller_id_number_id = element(split(":", aws_connect_phone_number.this.id), 1)
  }

  tags = var.tags
}

resource "aws_connect_routing_profile" "this" {
  instance_id = aws_connect_instance.this.id
  name        = "${local.environment}-routing-profile"
  description = "Routing profile for ${replace(var.environment, "_", " ")} environment"

  default_outbound_queue_id = element(split(":", aws_connect_queue.this.id), 1)

  queue_configs {
    channel  = "VOICE"
    queue_id = element(split(":", aws_connect_queue.this.id), 1)
    priority = 1
    delay    = 0
  }

  media_concurrencies {
    channel     = "VOICE"
    concurrency = 1
  }

  tags = var.tags
}

resource "aws_connect_user" "this" {
  for_each = var.connect_users

  instance_id = aws_connect_instance.this.id
  name        = lower(join("", [substr(each.key, 0, 1), split("_", each.key)[1]]))
  password    = random_password.connect_password[each.key].result

  security_profile_ids = [element(split(":", data.aws_connect_security_profile.this[each.key].id), 1)]

  routing_profile_id = element(split(":", aws_connect_routing_profile.this.id), 1)

  identity_info {
    first_name = title(split("_", each.key)[0])
    last_name  = title(split("_", each.key)[1])
    email      = each.value.email
  }

  phone_config {
    after_contact_work_time_limit = 0
    phone_type                    = "SOFT_PHONE"
  }
}

resource "aws_secretsmanager_secret" "connect_user_credentials" {
  name        = "${var.environment}_connect_usernames_passwords"
  description = "${replace(var.environment, "_", " ")} connect user credentials"

  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "connect_user_credentials_version" {
  secret_id = aws_secretsmanager_secret.connect_user_credentials.id

  secret_string = jsonencode({
    for user, details in var.connect_users :
    lower(join("", [substr(user, 0, 1), split("_", user)[1]])) => random_password.connect_password[user].result
  })
}

resource "random_password" "connect_password" {
  for_each = var.connect_users

  length = 12

  upper   = true
  lower   = true
  special = true
  numeric = true
}
