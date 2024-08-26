# --------------- BastionIAM --------------- #
data "aws_iam_policy_document" "bastionTrust" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}
data "aws_iam_policy" "bastionPolicy" {
  arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
resource "aws_iam_role" "bastionRole" {
  name               = "apdev-bastion-role"
  assume_role_policy = data.aws_iam_policy_document.bastionTrust.json
}
resource "aws_iam_role_policy_attachment" "bastionAttachment" {
  role       = aws_iam_role.bastionRole.name
  policy_arn = data.aws_iam_policy.bastionPolicy.arn
}
resource "aws_iam_instance_profile" "bastionProfile" {
  name = "apdev-bastion-profile"
  role = aws_iam_role.bastionRole.name
}
