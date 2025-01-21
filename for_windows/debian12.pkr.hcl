packer {
  required_plugins {
    vmware = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/vmware"
    }
  }
}

variable "vm_name" {
  default = "debian12-vm"
}

source "vmware-iso" "debian12" {
  iso_url           = "https://cdimage.debian.org/debian-cd/12.9.0/amd64/iso-cd/debian-12.9.0-amd64-netinst.iso"
  iso_checksum      = "sha256:1257373c706d8c07e6917942736a865dfff557d21d76ea3040bb1039eb72a054"
  communicator      = "ssh"
  ssh_username      = "root"
  ssh_password      = "1234"
  ssh_timeout       = "20m"
  http_directory    = "http"
  headless          = true

  cpus              = 4
  memory            = 6048
  disk_size         = 20480

  vmx_data = {
    "ethernet0.present"      = "TRUE"
    "ethernet0.connectiontype" = "nat"
  }

  boot_wait         = "10s"

boot_command = [
  "<esc><wait>",
  "auto ",
  "url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg ", // Path to preseed
  "debian-installer=en_US ",
  "locale=en_US ",
  "keyboard-configuration/layoutcode=us ",
  "netcfg/get_hostname=debian ",
  "netcfg/get_domain=local ",
  "fb=false ",
  "debconf/frontend=noninteractive ",
  "console-setup/ask_detect=false ",
  "console-setup/layoutcode=us ",
  "initrd=initrd.gz ",
  "quiet ",
  "--- <enter>"
]


  output_directory  = "output-vm"
  shutdown_command  = "shutdown -P now"
}

build {
  sources = ["source.vmware-iso.debian12"]

provisioner "shell" {
  inline = [
    "sudo apt update -y",
    "sudo apt install -y sudo git",
    "sudo apt install -y software-properties-common",
    "sudo apt install -y ansible"
  ]
}
}
