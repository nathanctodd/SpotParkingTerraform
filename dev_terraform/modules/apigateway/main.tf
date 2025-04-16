resource "aws_api_gateway_rest_api" "beam_me_sentry_api_gateway" {
  name        = "beam_me_sentry_api_gateway"
  description = "API Gateway that proxies to Star Command EC2"
}

resource "aws_api_gateway_resource" "api_resource" {
  rest_api_id = aws_api_gateway_rest_api.beam_me_sentry_api_gateway.id
  parent_id   = aws_api_gateway_rest_api.beam_me_sentry_api_gateway.root_resource_id
  path_part   = "beam-me-up"
}

resource "aws_api_gateway_method" "api_method" {
  rest_api_id   = aws_api_gateway_rest_api.beam_me_sentry_api_gateway.id
  resource_id   = aws_api_gateway_resource.api_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "http_integration" {
  rest_api_id             = aws_api_gateway_rest_api.beam_me_sentry_api_gateway.id
  resource_id             = aws_api_gateway_resource.api_resource.id
  http_method             = aws_api_gateway_method.api_method.http_method
  integration_http_method = "POST"
  type                    = "HTTP"
  uri                     = "http://${var.star_command_ec2_public_ip}/beam-me-up"
  passthrough_behavior    = "WHEN_NO_MATCH"
  content_handling        = "CONVERT_TO_TEXT"
  request_parameters      = {}
}

resource "aws_api_gateway_deployment" "api_deployment" {
  depends_on  = [aws_api_gateway_integration.http_integration]
  rest_api_id = aws_api_gateway_rest_api.beam_me_sentry_api_gateway.id
}
