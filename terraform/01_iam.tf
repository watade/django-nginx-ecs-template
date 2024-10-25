# ECSタスク実行ロール
resource "aws_iam_role" "ecs_task_execution_role" {
  name                = "ECSTaskExecutionRole"
  description         = "Allows ECS tasks to call AWS services on your behalf."
  managed_policy_arns = [data.aws_iam_policy.amazon_ecs_task_execution_role_policy.arn]
  assume_role_policy  = data.aws_iam_policy_document.ecs_tasks_assume_role_policy.json
}

data "aws_iam_policy" "amazon_ecs_task_execution_role_policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECSタスクロール
resource "aws_iam_role" "ecs_task_role" {
  name                = "DjangoECSTaskRole"
  description         = "Allows ECS tasks to call AWS services on your behalf."
  managed_policy_arns = [data.aws_iam_policy.amazon_ecs_container_service_role.arn]
  assume_role_policy  = data.aws_iam_policy_document.ecs_tasks_assume_role_policy.json
}

data "aws_iam_policy" "amazon_ecs_container_service_role" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceRole"
}

# 両IAMロールの信頼ポリシー
data "aws_iam_policy_document" "ecs_tasks_assume_role_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}
