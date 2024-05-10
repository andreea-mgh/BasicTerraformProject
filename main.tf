provider "aws" {
  region = "eu-west-1"
}

// SQS Queue
resource "aws_sqs_queue" "tfproject_queue" {
  name                      = "tfproject_queue"
  delay_seconds             = 0
  max_message_size          = 262144
  message_retention_seconds = 345600
  visibility_timeout_seconds= 30
  receive_wait_time_seconds = 0
}

// SNS Topic
resource "aws_sns_topic" "tfproject_topic" {
  name = "tfproject_topic"
}

// Lambda
resource "aws_lambda_function" "tfproject_lambda" {
  filename      = "lambda/lambda_function.zip"
  function_name = "tfproject_lambda"
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.8"

  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.tfproject_topic.arn
    }
  }
}



// permisiuni Lambda
resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda_exec_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      },
      Action    = "sts:AssumeRole"
    }]
  })

}
resource "aws_iam_policy_attachment" "lambda_exec_role_attachment" {
  name       = "lambda_exec_role_attachment"
  roles      = [aws_iam_role.lambda_exec_role.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

// permisiuni SQS -> Lambda
resource "aws_lambda_permission" "allow_sqs" {
  statement_id  = "AllowExecutionFromSQS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.tfproject_lambda.function_name
  principal     = "sqs.amazonaws.com"

  source_arn = aws_sqs_queue.tfproject_queue.arn
}
resource "aws_iam_policy_attachment" "lambda_exec_role_sqs_attachment" {
  name       = "lambda_exec_role_sqs_attachment"
  roles      = [aws_iam_role.lambda_exec_role.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonSQSFullAccess"
}

// Lambda Event Source Mapping
resource "aws_lambda_event_source_mapping" "sqs_mapping" {
  event_source_arn  = aws_sqs_queue.tfproject_queue.arn
  function_name     = aws_lambda_function.tfproject_lambda.function_name
  batch_size        = 10
}

// Lambda -> SNS
resource "aws_iam_policy" "lambda_sns_policy" {
  name        = "lambda_sns_policy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = "sns:Publish",
      Resource = aws_sns_topic.tfproject_topic.arn
    }]
  })
}
resource "aws_iam_role_policy_attachment" "lambda_sns_policy_attachment" {
  policy_arn = aws_iam_policy.lambda_sns_policy.arn
  role       = aws_iam_role.lambda_exec_role.name
}

// SNS -> Email
resource "aws_sns_topic_subscription" "sns_subscription" {
  topic_arn = aws_sns_topic.tfproject_topic.arn
  protocol  = "email"
  endpoint  = "YOUR EMAIL HERE"
}
