terraform {
  backend "s3" {
    bucket       = "nginx-php-tf-state"
    key          = "nginx-php/dev/terraform.tfstate"
    region       = "us-east-2"
    encrypt      = true
    use_lockfile = true
  }
}