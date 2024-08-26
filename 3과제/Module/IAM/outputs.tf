# --------------- BastionIAM --------------- #
output "bastionProfileName" {
  value = aws_iam_instance_profile.bastionProfile.id
}