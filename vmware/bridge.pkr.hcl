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
  }
}

source "vmware-iso" "debian" {
  iso_url           = "https://cdimage.debian.org/debian-cd/12.8.0/arm64/iso-cd/debian-12.8.0-arm64-netinst.iso"
  iso_checksum      = "sha256:b242a2c76375fb0b912afbc31bbf9a4c27276524daeea4e65e3d0da83eee9931"
  ssh_username      = "gagan"
  ssh_password      = "1234"
  ssh_timeout       = "5m"
  shutdown_command  = "echo '${var.user_pwd}' | sudo -S shutdown -P now"
  guest_os_type     = "arm-debian12-64"
  disk_adapter_type = "nvme"
  version           = 20
  http_directory    = "../http/debian"
  boot_command = [
    "c",
    "linux /install.a64/vmlinuz",
    " auto-install/enable=true",
    " debconf/priority=critical",
    " netcfg/hostname=debian-12",
    " netcfg/get_domain=",
    " preseed/url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg --- quiet",
    "<enter>",
    "initrd /install.a64/initrd.gz",
    "<enter>",
    "boot",
    "<enter><wait>"
  ]

  memory               = 6048
  cpus                 = 4
  disk_size            = 40480
  vm_name              = "Debian 12.8(arm64)"
  network_adapter_type = "e1000e"
  output_directory     = "debian"
  usb                  = true

  # Enable Bridged Networking
  vmx_data = {
    "usb_xhci.present"       = "true"
    "ethernet0.connectionType" = "bridged"    # Set network to bridged mode
    "ethernet0.virtualDev"     = "e1000e"     # Network adapter type
    "ethernet0.addressType"    = "generated"  # Use a dynamically generated MAC address
  }
}

build {
  sources = ["sources.vmware-iso.debian"]

  # Copy SSH keys archive
  provisioner "file" {
    source      = "../ssh.tar.gz"
    destination = "/tmp/ssh.tar.gz"
  }

  # Enable root autologin
  provisioner "shell" {
    inline = [
      "sudo mkdir -p /etc/systemd/system/getty@tty1.service.d/",
      "echo '[Service]' | sudo tee /etc/systemd/system/getty@tty1.service.d/override.conf",
      "echo 'ExecStart=' | sudo tee -a /etc/systemd/system/getty@tty1.service.d/override.conf",
      "echo 'ExecStart=-/sbin/agetty --autologin root --noclear %I $TERM' | sudo tee -a /etc/systemd/system/getty@tty1.service.d/override.conf",
      "sudo systemctl daemon-reload",
      "sudo systemctl restart getty@tty1"
    ]
  }

  # Cleanup and merge VMDK files
  provisioner "shell-local" {
    inline = [
      "/Applications/VMware\\ Fusion.app/Contents/Library/vmware-vdiskmanager -r debian/disk.vmdk -t 0 debian/final.vmdk",
      "echo 'VMDK files successfully merged into final.vmdk'"
    ]
  }
}
