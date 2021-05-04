resource "random_password" "gardener_password" {
  length  = 16
  special = false
}
