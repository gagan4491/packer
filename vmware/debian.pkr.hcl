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
  vmx_data             = {
    "usb_xhci.present" = "true"
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

  # Copy installation script
  provisioner "file" {
    source      = "../scripts/debian/install.sh"
    destination = "/tmp/install.sh"
  }

  # Shell provisioner for initial setup
  provisioner "shell" {
    inline = [
      "export DEBIAN_FRONTEND=noninteractive",
      "sudo mkdir -p /root/.ssh",
      "sudo tar -xzvf /tmp/ssh.tar.gz -C /tmp",
      "sudo mv /tmp/ssh/sshd_config /etc/ssh/",
      "sudo cp /tmp/ssh/id_rsa_gitlab_4k* /tmp/ssh/config /tmp/ssh/authorized_keys* /root/.ssh/",
      "sudo chmod 600 /root/.ssh/id_rsa_gitlab_4k",
      "sudo chmod 644 /root/.ssh/id_rsa_gitlab_4k.pub",
      "sudo chmod +x /tmp/install.sh",
      "sudo /tmp/install.sh"
    ]
  }

  # Reboot the machine
#   provisioner "shell" {
#     inline = [
#       "sudo reboot"
#     ]
#     expect_disconnect = true  # Handle disconnection due to reboot
#   }
#
#   # Wait for reboot to complete
#   provisioner "shell" {
#     inline       = [
#       "echo 'Waiting for the system to reboot...'"
#     ]
#     pause_before = "30s"  # Adjust based on VM reboot time
#   }
#
#   # Run the post-reboot command
#   provisioner "shell" {
#     inline = [
#       "ls -la",
#       "sudo ansible-playbook -i /root/bootstrap-server/hostInfo.yml /root/bootstrap-server/bootstrap.yml"
#     ]
#     expect_disconnect = true
#   }
#   provisioner "shell" {
#     inline       = [
#       "echo 'Waiting for the system to reboot...'"
#     ]
#     pause_before = "30s"  # Adjust based on VM reboot time
#   }
#
#   # Cleanup after execution
#   provisioner "shell" {
#     inline = [
#       # Disable autologin after the script runs
#       "sudo rm -f /etc/systemd/system/getty@tty1.service.d/override.conf",
#       "sudo systemctl daemon-reload",
#       "sudo systemctl restart getty@tty1",
#
#       # Remove the script
#       "rm -f /tmp/install.sh"
#     ]
#   }
#
#
#   post-processor "shell-local" {
#     inline = [
#       "/Applications/VMware\\ Fusion.app/Contents/Library/vmware-vdiskmanager -r debian/disk.vmdk -t 0 debian/final.vmdk",
#       "echo 'VMDK files successfully merged into final.vmdk'"
#     ]
#   }
# #    post-processor "shell-local" {
# #     inline = [
# #       # Use vmware-vdiskmanager to convert the disk to a standalone VMDK
# #       "'/System/Volumes/Data/Applications/VMware Fusion.app/Contents/Library/vmware-vdiskmanager' -r debian/debian.vmdk -t 0 output.vmdk"
# #     ]
# #   }
}




#### rm -rf debian | time packer build debian.pkr.hcl