module "test" {
  source = "../"

  domain           = "dscott-test.azure.dustinscott.io"
  cluster_name     = "dscott-test"
  pull_secret_path = "/Users/dscott/.azure/aro-pull-secret.txt"
  aro_version      = "4.14.16"

  # NOTE: uncomment to test a private cluster
  # api_server_profile      = "Private"
  # ingress_profile         = "Private"
  # restrict_egress_traffic = true

  tags = {
    environment = "sandbox"
    email       = "dscott@redhat.com"
  }
}
