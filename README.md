# terraform-static-site

Terraform code to deploy the infrastructure needed to host https://www.cassidynelemans.com

Website repo is located here: https://github.com/nelemansc/hugo-static-site

Deploys the following:
- Bare domain S3 bucket
- www domain S3 bucket
- Cloudfront distribution for TLS support
- Lambda@Edge Lambda function to add HTTP security headers returned as part of the Cloudfront viewer response
- Route53 records to resolve the bare and www to the Cloudfront distribution
