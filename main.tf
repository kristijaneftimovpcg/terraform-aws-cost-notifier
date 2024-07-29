data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/lambda.py"
  output_path = "${path.module}/lambda_function_payload.zip"
}

data "aws_caller_identity" "current" {}

resource "aws_lambda_function" "budget_calculation" {
  filename         = data.archive_file.lambda.output_path
  function_name    = var.lambda-name
  source_code_hash = data.archive_file.lambda.output_base64sha256
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda.lambda_handler"
  runtime          = var.python-runtime
  timeout          = 60
  memory_size      = 128

  environment {
    variables = {
      sns_topic_arn    = aws_sns_topic.budget_notifications.arn
      region           = var.aws-region
      project_name     = var.project-name
      calculation_type = var.calculation-type
      account_id       = data.aws_caller_identity.current.account_id
    }
  }
}

resource "aws_iam_role" "lambda_role" {
  name = var.lambda-role-name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "lambda_policy_attachment" {
  name       = "lambda-cloudwatch-policy-attachment"
  roles      = [aws_iam_role.lambda_role.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_cloudwatch_event_rule" "cost_trigger" {
  name                = var.cloudwatch-rule-name
  schedule_expression = var.cron-expression
  depends_on          = [aws_lambda_function.budget_calculation]
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.cost_trigger.name
  target_id = "invoke-lambda"
  arn       = aws_lambda_function.budget_calculation.arn
}

resource "aws_lambda_permission" "invoke_lambda" {
  statement_id  = "AllowExecutionFromCloudWatchRules"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.budget_calculation.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.cost_trigger.arn
}

data "aws_iam_policy_document" "lambda_access_document" {
  statement {
    effect = "Allow"
    actions = [
      "ce:GetCostAndUsage",
      "ce:GetCostForecast",
      "sns:Publish"
    ]
    resources = ["*"]
  }
  depends_on = [aws_sns_topic.budget_notifications]
}

resource "aws_iam_policy" "lambda_access_policy" {
  name        = "lambda-access"
  path        = "/"
  description = "IAM policy for setting permissions for Lambda"
  policy      = data.aws_iam_policy_document.lambda_access_document.json
}

resource "aws_iam_role_policy_attachment" "lambda_access_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_access_policy.arn

  depends_on = [data.aws_iam_policy_document.lambda_access_document]
}

resource "aws_sns_topic" "budget_notifications" {
  name         = var.sns-topic-name
  display_name = var.sns-topic-name
}

data "aws_iam_policy_document" "sns_permissions" {
  policy_id = "__cost_calculation"

  statement {
    effect = "Allow"
    actions = [
      "SNS:Subscribe",
      "SNS:SetTopicAttributes",
      "SNS:RemovePermission",
      "SNS:Receive",
      "SNS:Publish",
      "SNS:ListSubscriptionsByTopic",
      "SNS:GetTopicAttributes",
      "SNS:DeleteTopic",
      "SNS:AddPermission",
    ]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    resources = [
      aws_sns_topic.budget_notifications.arn
    ]
  }
}

resource "aws_sns_topic_policy" "cost_calculation" {
  arn    = aws_sns_topic.budget_notifications.arn
  policy = data.aws_iam_policy_document.sns_permissions.json
}

resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn              = aws_sns_topic.budget_notifications.arn
  protocol               = var.sns-protocol
  endpoint               = var.sns-endpoint
  endpoint_auto_confirms = true
}

resource "aws_sns_topic_subscription" "email_PO_subscription" {
  count                  = var.sns-po-endpoint != "" ? 1 : 0
  topic_arn              = aws_sns_topic.budget_notifications.arn
  protocol               = var.sns-protocol
  endpoint               = var.sns-po-endpoint
  endpoint_auto_confirms = true
}

resource "aws_budgets_budget" "monthly_cost_budget" {
  count = var.budget-threshold > 0 ? 1 : 0 // deploy the resource, only if budget-threshold is greater than 0

  name         = "MonthlyCostBudget"
  budget_type  = "COST"
  limit_amount = var.budget-threshold
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  cost_types {
    include_tax          = true
    include_subscription = true
    use_blended          = false
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    notification_type          = "ACTUAL"
    threshold                  = 80.0
    threshold_type             = "PERCENTAGE"
    subscriber_email_addresses = [var.sns-endpoint]
  }
}
