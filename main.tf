provider "aws" {
  region = "us-east-1"
}

# Generate a random suffix so your bucket name is globally unique
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# 1. Create the S3 Bucket
resource "aws_s3_bucket" "website_bucket" {
  bucket = "my-terraform-static-site-${random_id.bucket_suffix.hex}"
}

# 2. Enable Static Website Hosting
resource "aws_s3_bucket_website_configuration" "website_config" {
  bucket = aws_s3_bucket.website_bucket.id

  index_document {
    suffix = "index.html"
  }
}

# 3. Allow Public Access to the Bucket
resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket = aws_s3_bucket.website_bucket.id

  block_public_acls = false
  block_public_policy = false
  ignore_public_acls = false
  restrict_public_buckets = false
}

# 4. Attach a Bucket Policy to Make Objects Publicly Readable
resource "aws_s3_bucket_policy" "public_read_policy" {
  bucket = aws_s3_bucket.website_bucket.id
  depends_on = [aws_s3_bucket_public_access_block.public_access]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "PublicReadGetObject"
        Effect = "Allow"
        Principal = "*"
        Action = "s3:GetObject"
        Resource = "${aws_s3_bucket.website_bucket.arn}/*"
      }
    ]
  })
}

# 5. Upload index.html to S3
resource "aws_s3_object" "index_file" {
  bucket = aws_s3_bucket.website_bucket.id
  key = "index.html"
  source = "index.html"
  content_type = "text/html"
}

# Output the live website URL
output "website_url" {
  value = "http://${aws_s3_bucket_website_configuration.website_config.website_endpoint}"
}


