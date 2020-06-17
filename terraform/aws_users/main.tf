locals {
  tags = jsondecode(var.SSDS_INFRA_TAGS)
  prefix = "submissions/1d4d15e5-2b8d-404c-b92e-c692a4251e60"
  users = jsondecode(file("users.json"))
}

resource "aws_iam_user" "submitter" {
  count         = length(local.users)
  name          = local.users[count.index]["name"]
  path          = "/"
  force_destroy = true
  tags          = local.tags
}

data "aws_iam_policy_document" "prefixes" {
  count = length(local.users)
  # statement {
  #   actions   = ["s3:ListBucket"]
  #   resources = ["arn:aws:s3:::${var.SSDS_S3_BUCKET}"]
  #   condition {
  #     test     = "StringLike"
  #     variable = "s3:prefix"
  #     values   = concat(local.users[count.index]["s3_prefixes"],
  #                       formatlist("%s/*", local.users[count.index]["s3_prefixes"]))
  #   }
  # }
  statement {
    actions   = ["s3:*"]
    resources = formatlist("arn:aws:s3:::${var.SSDS_S3_BUCKET}/%s/*", local.users[count.index]["s3_prefixes"])
  }
}

resource "aws_iam_policy" "s3-prefix-permissions" {
  count = length(local.users)
  name  = "${local.users[count.index]["name"]}-s3-write"
  path  = "/"

  policy = data.aws_iam_policy_document.prefixes[count.index].json
}

resource "aws_iam_policy_attachment" "s3-prefix-permissions" {
  count      = length(local.users)
  name       = "s3-prefix-permissions-attachment"
  users      = [aws_iam_user.submitter[count.index].name]
  policy_arn = aws_iam_policy.s3-prefix-permissions[count.index].arn
}
