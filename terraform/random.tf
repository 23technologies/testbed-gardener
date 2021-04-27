resource "random_password" "gardener_password" {
  length  = 24
  special = false
}
