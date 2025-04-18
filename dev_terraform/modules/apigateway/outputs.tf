output "beam_me_sentry_api_gateway_url" {
  value = "https://${aws_api_gateway_rest_api.beam_me_sentry_api_gateway.id}.execute-api.${var.aws_region}.amazonaws.com/"
}