terraform {
 backend "gcs" {
   bucket = "tf-admin-dev-nurz6wts"
   prefix  = "terraform/state/dev"
 }
}
