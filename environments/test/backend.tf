terraform {
 backend "gcs" {
   bucket = "tf-admin-aabm0pul"
   prefix  = "terraform/state/test"
 }
}
