output "arn" {
  value       = aws_iam_role.role.arn
  description = "ARN role iam"
}

output "name" {
  value       = aws_iam_role.role.name
  description = "name role iam"
}
