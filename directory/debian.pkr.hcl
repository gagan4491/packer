variable "user_name" {
  type    = string
  default = "gagan"
}

variable "user_pwd" {
  type    = string
  default = "1234"
}

packer {
  required_version = "= 1.11.2"
  required_plugins {
    vmware = {
      version = "= 1.1.0"
      source  = "github.com/hashicorp/vmware"
    }
    # Uncomment or add other plugins if needed
    # vagrant = {
    #   version = "= 1.1.5"
    #   source = "github.com/hashicorp/vagrant"
    # }
  }
}

source "vmware-iso" "debian" {
  iso_url           = "https://cdimage.debian.org/debian-cd/12.8.0/arm64/iso-cd/debian-12.8.0-arm64-netinst.iso"
  iso_checksum      = "sha256:b242a2c76375fb0b912afbc31bbf9a4c27276524daeea4e65e3d0da83eee9931"
  ssh_username      = "${var.user_name}"
  ssh_password      = "${var.user_pwd}"
  ssh_timeout       = "5m"
  shutdown_command  = "echo '${var.user_pwd}' | sudo -S shutdown -P now"
  guest_os_type     = "arm-debian12-64"
  disk_adapter_type = "nvme"
  version           = 20
  http_directory    = "../http/debian"
  boot_command      = [
    "c",
    "linux /install.a64/vmlinuz",
    "auto-install/enable=true",
    "debconf/priority=critical",
    "netcfg/hostname=debian-12",
    "netcfg/get_domain=",
    "preseed/url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg --- quiet",
    "<enter>",
    "initrd /install.a64/initrd.gz",
    "<enter>",
    "boot",
    "<enter><wait>"
  ]
  memory               = 6048
  cpus                 = 4
  disk_size            = 40480
  vm_name              = "Debian 12.0 (arm64)"
  network_adapter_type = "e1000e"
  output_directory     = "debian"
  usb                  = true
  vmx_data             = {
    "usb_xhci.present" = "true"
  }
}

build {
  sources = ["sources.vmware-iso.debian"]

  provisioner "shell" {
    inline = [
      "echo '${var.user_pwd}' | sudo -S apt-get update",
      "echo '${var.user_pwd}' | sudo -S apt-get install -y sudo"
    ]
  }

  provisioner "shell" {
    execute_command = "echo '${var.user_pwd}' | {{ .Vars }} sudo -S -E sh '{{ .Path }}'"
    inline          = [
      "echo '${var.user_name} ALL=(ALL) NOPASSWD:ALL' | sudo tee /etc/sudoers.d/${var.user_name}"
    ]
  }

  provisioner "shell" {
    environment_vars = [
      "USER_NAME=${var.user_name}",
      "VMWARE=1"
    ]
    scripts = [
      "../scripts/debian/create-user.sh",
      # "../scripts/debian/disable-ipv6.sh",
      "../scripts/debian/install.sh"
    ]
  }

  provisioner "file" {
    source      = "../ssh/id_rsa"
    destination = "/home/${var.user_name}/.ssh/id_rsa"
  }

  provisioner "file" {
    source      = "../ssh/id_rsa.pub"
    destination = "/home/${var.user_name}/.ssh/id_rsa.pub"
  }

  provisioner "shell" {
    inline = [
      "chmod 600 /home/${var.user_name}/.ssh/id_rsa",
      "chmod 644 /home/${var.user_name}/.ssh/id_rsa.pub",
      "chown ${var.user_name}:${var.user_name} /home/${var.user_name}/.ssh/id_rsa",
      "chown ${var.user_name}:${var.user_name} /home/${var.user_name}/.ssh/id_rsa.pub"
    ]
  }

  # Uncomment and configure the following section if you want to use Vagrant post-processors
  # post-processor "vagrant" {
  #   compression_level              = 9
  #   vagrantfile_template_generated = true
  # }
}
