variable "headless" {
  type    = string
  default = "true"
}

variable "mirror" {
  type    = string
  default = "http://cdimage.ubuntu.com/ubuntu-legacy-server/releases"
}

# OS versions and ISO file
locals {
  version_major     = "20"
  version_minor     = "04"
  version_patch     = "1"
  iso_checksum_type = "sha256"
  iso_checksum      = "f11bda2f2caed8f420802b59f382c25160b114ccc665dbac9c5046e7fceaced2"
  iso_url           = "${var.mirror}/${local.version_major}.${local.version_minor}/release/ubuntu-${local.version_major}.${local.version_minor}.${local.version_patch}-legacy-server-amd64.iso"
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
  boot_command            = ["<esc><wait>", "<esc><wait>", "<enter><wait>", "/install/vmlinuz", " auto=true", " url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg", " locale=en_US<wait>", " console-setup/ask_detect=false<wait>", " console-setup/layoutcode=us<wait>", " console-setup/modelcode=pc105<wait>", " debconf/frontend=noninteractive<wait>", " debian-installer=en_US<wait>", " fb=false<wait>", " initrd=/install/initrd.gz<wait>", " kbd-chooser/method=us<wait>", " keyboard-configuration/layout=USA<wait>", " keyboard-configuration/variant=USA<wait>", " netcfg/get_domain=vm<wait>", " netcfg/get_hostname=vagrant<wait>", " grub-installer/bootdev=/dev/sda<wait>", " noapic<wait>", " -- <wait>", "<enter><wait>"]
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
  boot_command            = [
    "<esc><wait>",
    "<esc><wait>",
    "<enter><wait>",
    "/install/vmlinuz",
    " auto=true",
    " url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg",
    " net.ifnames=0",
    " locale=en_US<wait>",
    " console-setup/ask_detect=false<wait>",
    " console-setup/layoutcode=us<wait>",
    " console-setup/modelcode=pc105<wait>",
    " debconf/frontend=noninteractive<wait>",
    " debian-installer=en_US<wait>",
    " fb=false<wait>",
    " initrd=/install/initrd.gz<wait>",
    " kbd-chooser/method=us<wait>",
    " keyboard-configuration/layout=USA<wait>",
    " keyboard-configuration/variant=USA<wait>",
    " netcfg/get_domain=vm<wait>",
    " netcfg/get_hostname=vagrant<wait>",
    " grub-installer/bootdev=/dev/sda<wait>",
    " noapic<wait>",
    " -- <wait>",
    "<enter><wait>",
  ]
  boot_wait            = "${local.boot_wait}"
  disk_size            = "${local.disk_size}"
  guest_os_type        = "Ubuntu_64"
  headless             = "${var.headless}"
  http_directory       = "http"
  iso_checksum         = "${local.iso_checksum_type}:${local.iso_checksum}"
  iso_url              = "${local.iso_url}"
  output_directory     = "output/virtualbox-iso"
  post_shutdown_delay  = "10s"
  shutdown_command     = "sudo systemctl poweroff"
  ssh_password         = "vagrant"
  ssh_timeout          = "${local.ssh_timeout}"
  ssh_username         = "vagrant"
  vboxmanage           = [
    ["modifyvm", "{{ .Name }}", "--memory", "${local.memory}"],
    ["modifyvm", "{{ .Name }}", "--cpus", "${local.cpus}"]
  ]
  vm_name              = "packer-ubuntu-${local.version_major}.${local.version_minor}-amd64"
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
