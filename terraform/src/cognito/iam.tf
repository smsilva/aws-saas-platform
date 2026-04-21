data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "dynamodb_query" {
  statement {
    effect    = "Allow"
    actions   = ["dynamodb:Query"]
    resources = ["${var.dynamodb_table_arn}/index/client-id-index"]
  }
}

resource "aws_iam_role" "lambda" {
  name               = "${var.name}-pre-token-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "dynamodb_query" {
  name   = "DynamoDBTenantRegistry"
  role   = aws_iam_role.lambda.id
  policy = data.aws_iam_policy_document.dynamodb_query.json
}
