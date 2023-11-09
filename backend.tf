terraform {
  backend "s3" {
    bucket         = "s3-terraform-state-use1"
    key            = "terraform.tfstate"   # State file name
    region         = "us-east-1"           # Use your desired AWS region
    encrypt        = true                  # Optionally, enable server-side encryption
    dynamodb_table = "ddb-statelock-table" # Optional, use a DynamoDB table for state locking
    # profile        = "sd2488.nashtech"
  }
}
