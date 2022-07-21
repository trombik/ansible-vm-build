variable "headless" {
  type    = string
  default = "false"
}

variable "mirror" {
  type    = string
  default = "https://cdimage.debian.org/cdimage/release"
}

# OS versions and ISO file
locals {
  version_major     = "11"
  version_minor     = "4"
  version_patch     = "0"
  code_name         = "bullseye"
  iso_checksum_type = "sha256"
  iso_checksum      = "d490a35d36030592839f24e468a5b818c919943967012037d6ab3d65d030ef7f"
  # https://cdimage.debian.org/cdimage/release/11.3.0/amd64/iso-cd/debian-11.3.0-amd64-netinst.iso
  iso_url           = "${var.mirror}/${local.version_major}.${local.version_minor}.${local.version_patch}/amd64/iso-cd/debian-${local.version_major}.${local.version_minor}.${local.version_patch}-amd64-netinst.iso"
}

# image-related options
locals {
  ssh_timeout       = "30m"
  cpus              = "2"
  memory            = "1024"
  disk_size         = "40000"
  boot_wait         = "5s"
}

# auto-generated version
locals {
  box_version       = formatdate("YYYYMMDD.hhmm", timestamp())
}

source "qemu" "default" {
  boot_command            = [
    "<esc><wait>auto priority=critical preseed/url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg <wait>",
    "keymap=us <wait>",
    "tasks=standard <wait>",
    "choose-init/select_init=sysvinit<wait>",
    "<enter><wait>",
  ]
  boot_wait        = "${local.boot_wait}"
  disk_size        = "${local.disk_size}"
  headless         = "${var.headless}"
  http_directory   = "http"
  iso_checksum     = "${local.iso_checksum_type}:${local.iso_checksum}"
  iso_url          = "${local.iso_url}"
  output_directory = "output/qemu"
  qemuargs         = [
    ["-m", "${local.memory}"],
    ["-display", "none"],
    ["-smp", "${local.cpus}"]
  ]
  shutdown_command       = "sudo systemctl poweroff"
  ssh_password     = "vagrant"
  ssh_timeout      = "${local.ssh_timeout}"
  ssh_username     = "vagrant"
  vm_name          = "packer-ubuntu-${local.version_major}.${local.version_major}-amd64"
}

source "virtualbox-iso" "default" {
  boot_command           = [
    "<esc><wait>auto priority=critical preseed/url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg <wait>",
    "keymap=us <wait>",
    "tasks=standard <wait>",
    "<enter><wait>",
  ]
  boot_wait              = "${local.boot_wait}"
  disk_size              = "${local.disk_size}"
  guest_os_type          = "Debian_64"
  headless               = "${var.headless}"
  http_directory         = "http"
  iso_checksum           = "${local.iso_checksum_type}:${local.iso_checksum}"
  iso_url                = "${local.iso_url}"
  output_directory       = "output/virtualbox-iso"
  post_shutdown_delay    = "10s"
  shutdown_command       = "sudo /sbin/shutdown -h now"
  ssh_handshake_attempts = "200"
  ssh_password           = "vagrant"
  ssh_timeout            = "${local.ssh_timeout}"
  ssh_username           = "vagrant"
  vboxmanage             = [
    ["modifyvm", "{{ .Name }}", "--memory", "${local.memory}"],
    ["modifyvm", "{{ .Name }}", "--cpus", "${local.cpus}"],

    # disable paravirtprovider
    # https://www.dbarj.com.br/en/2017/11/fixing-virtualbox-crashing-macos-on-high-load-kernel-panic/
    ["modifyvm", "{{ .Name }}", "--paravirtprovider", "none"]
  ]
  vm_name                = "packer-debian-${local.version_major}.${local.version_minor}-amd64"
}

build {
  sources = ["source.qemu.default", "source.virtualbox-iso.default"]

  provisioner "shell" {
    scripts = [
      "scripts/apt.sh",
      "scripts/virtualbox.sh",
      "scripts/vagrant.sh",
      "scripts/sshd.sh",
      "scripts/cleanup.sh",
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
