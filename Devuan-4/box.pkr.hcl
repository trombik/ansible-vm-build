variable "headless" {
  type    = string
  default = "false"
}

variable "mirror" {
  type    = string
  default = "https://mirror.leaseweb.com/devuan"
}

# OS versions and ISO file
locals {
  version_major     = "4"
  version_minor     = "0"
  version_patch     = "0"
  code_name         = "chimaera"
  iso_checksum_type = "sha256"
  iso_checksum      = "0923470af430e3d582a635956bbe4c13abc18fbaa4704e6deef3b362833e0ef5"
  # https://mirror.leaseweb.com/devuan/devuan_chimaera/installer-iso/devuan_chimaera_4.0.0_amd64_netinstall.iso
  iso_url           = "${var.mirror}/devuan_${local.code_name}/installer-iso/devuan_${local.code_name}_${local.version_major}.${local.version_minor}.${local.version_patch}_amd64_netinstall.iso"
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
    "choose-init/select_init=sysvinit<wait>",
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
    ["modifyvm", "{{ .Name }}", "--cpus", "${local.cpus}"]
  ]
  vm_name                = "packer-devuan-${local.version_major}.${local.version_minor}-amd64"
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
