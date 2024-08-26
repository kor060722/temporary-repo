# --------------- Bucket --------------- #
output "randomBucketId" {
  value = aws_s3_bucket.randomBucket.id
}