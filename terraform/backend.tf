terraform {
  backend "s3" {
    bucket = "bsc.sandbox.terraform.state"
    key    = "get_me_out_of_here/terraform.tfstate"
    region = "us-east-2"
  }
}
