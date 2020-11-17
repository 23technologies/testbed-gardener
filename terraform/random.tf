resource "random_password" "gardener_password" {
  length           = 16
  special          = true
  override_special = "_%@"
}

resource "random_password" "k3s_token" {
  length           = 24
  special          = true
  override_special = "_%@"
}
