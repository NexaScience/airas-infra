terraform {
  backend "s3" {
    bucket         = "airas-terraform-state-427979936961"
    key            = "prod/terraform.tfstate"
    region         = "ap-northeast-1"
    dynamodb_table = "airas-terraform-lock"
    encrypt        = true
  }
}
