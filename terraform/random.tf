resource "random_password" "gardener_password" {
  length  = 24
  special = false
}

resource "random_password" "k3s_token" {
  length  = 24
  special = false
}
