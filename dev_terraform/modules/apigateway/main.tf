provider "aws" {
    region = "us-east-1"
}

resource "aws_api_gateway_rest_api" "api_gateway" {
    name        = "SpotParkingAPI"
    description = "API Gateway for activating a Lambda function"
}

resource "aws_api_gateway_resource" "api_resource" {
    rest_api_id = aws_api_gateway_rest_api.api_gateway.id
    parent_id   = aws_api_gateway_rest_api.api_gateway.root_resource_id
    path_part   = "trigger"
}

resource "aws_api_gateway_method" "api_method" {
    rest_api_id   = aws_api_gateway_rest_api.api_gateway.id
    resource_id   = aws_api_gateway_resource.api_resource.id
    http_method   = "POST"
    authorization = "NONE"
}

resource "aws_lambda_permission" "api_gateway_permission" {
    statement_id  = "AllowAPIGatewayInvoke"
    action        = "lambda:InvokeFunction"
    function_name = aws_lambda_function.lambda_function.function_name
    principal     = "apigateway.amazonaws.com"
    source_arn    = "${aws_api_gateway_rest_api.api_gateway.execution_arn}/*/*"
}

resource "aws_api_gateway_integration" "lambda_integration" {
    rest_api_id             = aws_api_gateway_rest_api.api_gateway.id
    resource_id             = aws_api_gateway_resource.api_resource.id
    http_method             = aws_api_gateway_method.api_method.http_method
    integration_http_method = "POST"
    type                    = "AWS_PROXY"
    uri                     = aws_lambda_function.lambda_function.invoke_arn
}

resource "aws_api_gateway_deployment" "api_deployment" {
    depends_on = [aws_api_gateway_integration.lambda_integration]
    rest_api_id = aws_api_gateway_rest_api.api_gateway.id
    stage_name  = "dev"
}
