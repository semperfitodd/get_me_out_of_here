module "lambda_authorizer" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "7.17.0"

  function_name = "${var.environment}_authorizer"
  description   = "${replace(var.environment, "_", " ")} api authorizer function"
  handler       = "app.lambda_handler"
  publish       = true
  runtime       = "python3.11"
  timeout       = 30

  environment_variables = {
    API_KEY_SECRET = aws_secretsmanager_secret.api_key.name
  }

  source_path = [
    {
      path             = "${path.module}/lambda_authorizer"
      pip_requirements = false
    }
  ]

  attach_policies = true
  policies        = ["arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"]

  attach_policy_statements = true
  policy_statements = {
    secrets = {
      effect    = "Allow",
      actions   = ["secretsmanager:*"],
      resources = [aws_secretsmanager_secret.api_key.arn]
    }
  }

  allowed_triggers = {
    AllowExecutionFromAPIGateway = {
      service    = "apigateway"
      source_arn = "${module.api_gateway.api_execution_arn}/*/*"
    }
  }

  cloudwatch_logs_retention_in_days = 3

  tags = var.tags
}

module "lambda_connect_outbound" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "7.17.0"

  function_name = "${var.environment}_connect_outbound"
  description   = "${replace(var.environment, "_", " ")} function to create outbound call with connect"
  handler       = "app.lambda_handler"
  publish       = true
  runtime       = "python3.11"
  timeout       = 30

  environment_variables = {
    CONNECT_FLOW_ID      = element(split(":", aws_connect_contact_flow.this.id), 1)
    CONNECT_INSTANCE_ID  = aws_connect_instance.this.id
    CONNECT_PHONE_NUMBER = aws_connect_phone_number.this.phone_number
  }

  source_path = [
    {
      path             = "${path.module}/lambda_connect_outbound"
      pip_requirements = false
    }
  ]

  attach_policies = true
  policies        = ["arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"]

  attach_policy_statements = true
  policy_statements = {
    connect = {
      effect = "Allow",
      actions = [
        "connect:StartOutboundVoiceContact",
        "connect:DescribeInstance",
      ],
      resources = ["*"]
    }
  }

  allowed_triggers = {
    AllowExecutionFromAPIGateway = {
      service    = "apigateway"
      source_arn = "${module.api_gateway.api_execution_arn}/*/*"
    }
  }

  cloudwatch_logs_retention_in_days = 3

  tags = var.tags
}

resource "aws_secretsmanager_secret" "api_key" {
  name        = "${var.environment}_api_key"
  description = "${replace(var.environment, "_", " ")} API key"

  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "api_key_version" {
  secret_id = aws_secretsmanager_secret.api_key.id

  secret_string = jsonencode({ "API_KEY" : "" })

  lifecycle {
    ignore_changes = [secret_string]
  }
}
