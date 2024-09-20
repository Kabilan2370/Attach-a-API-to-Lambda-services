
# Lambda

resource "aws_iam_role" "iam_role" {
  name               = "lambda_role"
  assume_role_policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [{
  "Action": "sts:AssumeRole",
  "Principal": {
  "Service": "lambda.amazonaws.com"
},
 "Effect": "Allow"
}]
})
}

resource "aws_lambda_function" "test_lambda" {
  
  function_name = "lambda_function"
  role          = aws_iam_role.iam_role.arn
  image_uri     = aws_account_id.dkr.ecr.us-east-1.amazonaws.com/adapterregistry
  :latest
  # image uri from elastic container registry
  package_type  = "Image"
  achitectures  = ["x86_64"]

  environment {
    variables = {
      foo = "bar"
    }
  }
}

# aws API Gateway

resource "aws_api_gateway_rest_api" "api" {
  body = jsonencode({
    openapi = "3.0.1"
    info = {
      title   = "example"
      version = "1.0"
    }
    paths = {
      "/path1" = {
        get = {
          x-amazon-apigateway-integration = {
            httpMethod           = "POST"
            payloadFormatVersion = "1.0"
            type                 = "HTTP_PROXY"
            uri                  = "https://ip-ranges.amazonaws.com/ip-ranges.json"
          }
        }
      }
    }
  })

  name = "Rest-API"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "resource" {
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "res-1"
  rest_api_id = aws_api_gateway_rest_api.api.id
}

resource "aws_api_gateway_method" "method" {
  authorization = "NONE"
  http_method   = "POST"
  resource_id   = aws_api_gateway_resource.resource.id
  rest_api_id   = aws_api_gateway_rest_api.api.id
  #lambda        = aws_lambda_function.test_lambda.arn
}

resource "aws_api_gateway_integration" "integration" {
  http_method = aws_api_gateway_method.method.http_method
  resource_id = aws_api_gateway_resource.resource.id
  rest_api_id = aws_api_gateway_rest_api.api.id
  type        = "AWS"
  uri         = aws_lambda_function.test_lambda.arn
}

resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = aws_api_gateway_rest_api.api.id

  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.api.body))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "stage" {
  deployment_id = aws_api_gateway_deployment.deployment.id
  rest_api_id   = aws_api_gateway_rest_api.api.id
  stage_name    = "Enthiran"
}



