data_dir = "/opt/nomad"

region = "{CLOUD}-{REGION}"

datacenter = "{CLOUD}-{ZONE}"

client {
  enabled      = true
  node_class   = "{INSTANCE-TYPE}"
  no_host_uuid = true
}
