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
#    "ethernet0.connectiontype" = "nat"
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

provisioner "file" {
    source      = "ssh.tar.gz"
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
    source      = "install.sh"
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
 provisioner "shell" {
   inline = [
     "sudo reboot"
   ]
   expect_disconnect = true  # Handle disconnection due to reboot
 }
#
 # Wait for reboot to complete
 provisioner "shell" {
   inline       = [
     "echo 'Waiting for the system to reboot...'"
   ]
   pause_before = "30s"  # Adjust based on VM reboot time
 }
#
 # Run the post-reboot command
 provisioner "shell" {
   inline = [
     "ls -la",
     "sudo ansible-playbook -i /root/bootstrap-server/hostInfo.yml /root/bootstrap-server/bootstrap.yml"
   ]
   expect_disconnect = true
 }
 provisioner "shell" {
   inline       = [
     "echo 'Waiting for the system to reboot...'"
   ]
   pause_before = "30s"  # Adjust based on VM reboot time
 }
#
 # Cleanup after execution
 provisioner "shell" {
   inline = [
     # Disable autologin after the script runs
     "sudo rm -f /etc/systemd/system/getty@tty1.service.d/override.conf",
     "sudo systemctl daemon-reload",
     "sudo systemctl restart getty@tty1",
#
     # Remove the script
     "rm -f /tmp/install.sh"
   ]
 }


}




