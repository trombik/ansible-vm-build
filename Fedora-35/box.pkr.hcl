variable "headless" {
  type    = string
  default = "true"
}

variable "http_proxy" {
  type    = string
  default = "${env("http_proxy")}"
}

variable "https_proxy" {
  type    = string
  default = "${env("https_proxy")}"
}

variable "name" {
  type    = string
  default = "fedora-35"
}

variable "no_proxy" {
  type    = string
  default = "${env("no_proxy")}"
}

variable "qemu_display" {
  type    = string
  default = "none"
}

variable "mirror" {
  type    = string
  default = "http://download.fedoraproject.org/pub/fedora/linux"
}

locals {
  os_name           = "fedora"
  arch              = "amd64"
  version_major     = "35"
  mirror_directory  = "releases/35/Server/x86_64/iso"
  iso_name          = "Fedora-Server-dvd-x86_64-35-1.2.iso"
  iso_checksum      = "sha256:3fe521d6c7b12c167f3ac4adab14c1f344dd72136ba577aa2bcc4a67bcce2bc6"
  iso_url           = "${var.mirror}/${local.mirror_directory}/${local.iso_name}"
  vm_name           = "packer-${local.os_name}-${local.version_major}-${local.arch}"
  ks_path           = "ks-fedora.cfg"
}

locals {
  boot_command    = [
    "<up><wait><tab> inst.text inst.ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/${local.ks_path}<enter><wait>"
  ]
  http_directory  = "http"
}

# image-related options
locals {
  boot_wait         = "10s"
  ssh_timeout       = "60m"
  cpus              = "2"
  memory            = "1024"
  disk_size         = "40000"
}

source "qemu" "default" {
  boot_command     = "${local.boot_command}"
  boot_wait        = "5s"
  cpus             = "${local.cpus}"
  disk_size        = "${local.disk_size}"
  headless         = "${var.headless}"
  http_directory   = "${local.http_directory}"
  iso_checksum     = "${local.iso_checksum}"
  iso_url          = "${var.mirror}/${local.mirror_directory}/${local.iso_name}"
  memory           = "${local.memory}"
  output_directory = "qemu/output"
  qemuargs         = [["-m", "${local.memory}"], ["-display", "${var.qemu_display}"]]
  shutdown_command = "echo 'vagrant'|sudo -S shutdown -P now"
  ssh_password     = "vagrant"
  ssh_port         = 22
  ssh_timeout      = "10000s"
  ssh_username     = "vagrant"
  vm_name          = "${local.vm_name}"
}

source "virtualbox-iso" "default" {
  boot_command            = "${local.boot_command}"
  boot_wait               = "5s"
  cpus                    = "${local.cpus}"
  disk_size               = "${local.disk_size}"
  guest_additions_path    = "VBoxGuestAdditions_{{ .Version }}.iso"
  guest_os_type           = "Fedora_64"
  hard_drive_interface    = "sata"
  headless                = "${var.headless}"
  http_directory          = "${local.http_directory}"
  iso_checksum            = "${local.iso_checksum}"
  iso_url                 = "${var.mirror}/${local.mirror_directory}/${local.iso_name}"
  memory                  = "${local.memory}"
  output_directory        = "output/virtualbox-iso"
  shutdown_command        = "echo 'vagrant'|sudo -S shutdown -P now"
  ssh_password            = "vagrant"
  ssh_port                = 22
  ssh_timeout             = "10000s"
  ssh_username            = "vagrant"
  virtualbox_version_file = ".vbox_version"
  vm_name                 = "${local.vm_name}"
}

build {
  sources = ["source.qemu.default", "source.virtualbox-iso.default"]

  provisioner "shell" {
    environment_vars  = ["HOME_DIR=/home/vagrant", "http_proxy=${var.http_proxy}", "https_proxy=${var.https_proxy}", "no_proxy=${var.no_proxy}"]
    execute_command   = "echo 'vagrant' | {{ .Vars }} sudo -E -S bash '{{ .Path }}'"
    expect_disconnect = true
    scripts           = [
      "scripts/fix-slow-dns.sh",
      "scripts/update.sh",
      "scripts/build-tools.sh",
      "scripts/install-supporting-packages.sh",
      "scripts/motd.sh",
      "scripts/sshd.sh",
      "scripts/virtualbox.sh",
      "scripts/vmware.sh",
      "scripts/parallels.sh",
      "scripts/vagrant.sh",
      "scripts/real-tmp.sh",
      "scripts/cleanup.sh",
      "scripts/crypto-policy.sh",
      "scripts/minimize.sh"
    ]
  }

  post-processors {
    post-processor "vagrant" {
      output               = "{{.Provider}}.box"
    }
    post-processor "shell-local" {
      inline = [
        "bundle exec rake up",
        "bundle exec rake test",
      ]
    }
  }
}
