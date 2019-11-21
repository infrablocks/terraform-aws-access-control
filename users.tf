# This should use multiple instances of infrablocks/terraform-aws-user but since
# terraform doesn't support count or for_each on modules yet, we have to copy
# the contents here
resource "aws_iam_user" "user" {
  count = length(var.users)
  name = var.users[count.index].name
  force_destroy = true
}
