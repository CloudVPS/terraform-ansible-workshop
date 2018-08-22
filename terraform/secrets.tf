resource "random_string" "secret1" {
  length = 8
  special = false
}

resource "random_string" "secret2" {
  length = 16
  special = true
  override_special = "/@\" "
}
