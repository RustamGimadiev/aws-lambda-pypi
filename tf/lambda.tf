variable "zip_file_path" {
  type    = string
  default = ""
}

locals {
   code_zip_file = var.zip_file_path == "" ? "../out/lambda_pypicloud.zip" : var.zip_file_path
}

resource "aws_lambda_function" "pypicloud" {
  filename = local.code_zip_file
  source_code_hash = filebase64sha256(local.code_zip_file)
  function_name = "pypicloud"
  role = aws_iam_role.pypicloud.arn
  handler = "lambda_function.lambda_handler"
  memory_size = "256"
  publish = false
  timeout = "180"
  runtime = "python3.8"

  environment {
    variables = {
      "PYPICLOUD_CONF_REGION" = var.region
      "ENV_SECRET_ID" = aws_secretsmanager_secret.env.arn
      "AUTH_SECRET_ID" = aws_secretsmanager_secret.auth.arn
      "BUCKET" = var.package_bucket
      "BUCKET_REGION" = var.region
      "DYNAMO_REGION" = var.region
    }
  }

  tracing_config {
    mode = "Active"
  }
}

resource "aws_lambda_permission" "pypicloud" {
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.pypicloud.arn
  principal = "apigateway.amazonaws.com"
  source_arn = "${aws_apigatewayv2_api.pypicloud.execution_arn}/*/${aws_apigatewayv2_stage.default.name}"
}
