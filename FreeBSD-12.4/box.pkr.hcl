variable "headless" {
  type    = string
  default = "true"
}

variable "mirror" {
  type    = string
  default = "https://download.freebsd.org/ftp"
}

# OS versions and ISO file
locals {
  os_name           = "freebsd"
  arch              = "amd64"
  version_major     = "12"
  version_minor     = "4"
  iso_checksum_type = "sha512"
  iso_checksum      = "14f21f31f3bdb7ac593cb8c859cb5f1857cba0c5f0b92c081b0ee7b34d1d0d28cc3dd5e7c38e22a0176a902397afb3dce461bafd2673011efaa7c4f63dcd5db8"
  iso_url           = "${var.mirror}/releases/ISO-IMAGES/${local.version_major}.${local.version_minor}/FreeBSD-${local.version_major}.${local.version_minor}-RELEASE-${local.arch}-disc1.iso"
  vm_name           = "packer-${local.os_name}-${local.version_major}.${local.version_minor}-${local.arch}"
}

# image-related options
locals {
  boot_wait         = "10s"
  ssh_timeout       = "15m"
  cpus              = "2"
  memory            = "1024"
  disk_size         = "40000"
}

# auto-generated version
locals {
  box_version       = formatdate("YYYYMMDD.hhmm", timestamp())
}

source "qemu" "default" {
  boot_command     = [
    "2<enter><wait10><wait10><wait10>",
    "<enter><wait>",
    "mdmfs -s 100m md1 /tmp<enter><wait10>",
    "dhclient -l /tmp/dhclient.leases -p /tmp/dhclient.pid vtnet0<enter><wait10><wait10><wait10>",
    "fetch -o /tmp/installerconfig http://{{ .HTTPIP }}:{{ .HTTPPort }}/installerconfig<enter><wait5>",
    "bsdinstall script /tmp/installerconfig && reboot<enter>"
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
  shutdown_command = "sudo poweroff"
  ssh_password     = "vagrant"
  ssh_timeout      = "${local.ssh_timeout}"
  ssh_username     = "vagrant"
  vm_name          = "${local.vm_name}"
}

source "virtualbox-iso" "default" {
  boot_command         = [
    "2<enter><wait10><wait10>",
    "<enter><wait>",
    "mdmfs -s 100m md1 /tmp<enter><wait10>",
    "dhclient -l /tmp/dhclient.leases -p /tmp/dhclient.pid em0<enter><wait20>",
    "fetch -o /tmp/installerconfig http://{{ .HTTPIP }}:{{ .HTTPPort }}/installerconfig<enter><wait5>",
    "bsdinstall script /tmp/installerconfig && reboot<enter>"
  ]
  boot_wait            = "${local.boot_wait}"
  disk_size            = "${local.disk_size}"
  guest_additions_mode = "disable"
  guest_os_type        = "FreeBSD_64"
  hard_drive_interface = "ide"
  headless             = "${var.headless}"
  http_directory       = "http"
  iso_checksum         = "${local.iso_checksum_type}:${local.iso_checksum}"
  iso_url              = "${local.iso_url}"
  output_directory     = "output/virtualbox-iso"
  post_shutdown_delay  = "30s"
  shutdown_command     = "sudo poweroff"
  ssh_password         = "vagrant"
  ssh_timeout          = "${local.ssh_timeout}"
  ssh_username         = "vagrant"
  vboxmanage           = [
    ["modifyvm", "{{ .Name }}", "--memory", "${local.memory}"],
    ["modifyvm", "{{ .Name }}", "--cpus", "${local.cpus}"],

    # disable paravirtprovider
    # https://www.dbarj.com.br/en/2017/11/fixing-virtualbox-crashing-macos-on-high-load-kernel-panic/
    ["modifyvm", "{{ .Name }}", "--paravirtprovider", "none"]
  ]
  vm_name              = "${local.vm_name}"
}

build {
  sources = ["source.qemu.default", "source.virtualbox-iso.default"]

  provisioner "shell" {
    scripts = [
      "scripts/virtualbox.sh",
      "scripts/init.sh",
      "scripts/vagrant.sh",
      "scripts/sshd.sh",
      "scripts/cleanup.sh",
      "scripts/minimize.sh"
    ]
  }

  post-processors {
    post-processor "vagrant" {
      output               = "{{.Provider}}.box"
      vagrantfile_template = "vagrantfile_templates/${local.os_name}.rb"
    }
    post-processor "shell-local" {
      inline = [
        "bundle exec rake up",
        "bundle exec rake test",
      ]
    }
  }
}
