
resource "aws_lambda_function" "lambda_function" {
  filename         = "lambda_function.zip"
  function_name    = "SpotParkingLambda"
  handler          = "index.handler"
  runtime          = "nodejs18.x"
  role             = aws_iam_role.lambda_role.arn
  source_code_hash = filebase64sha256("lambda_function.zip")
}

