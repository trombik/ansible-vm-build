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
  version_major     = "13"
  version_minor     = "0"
  iso_checksum_type = "sha512"
  iso_checksum      = "8f58360e4259a04a262bc345e6c16708331bec40ec2d596a5b60d53f05d566a13ccf1e322df92be61c040261230df2f41d311aac174d5820828322dbca904a8e"
  iso_url           = "${var.mirror}/releases/ISO-IMAGES/${local.version_major}.${local.version_minor}/FreeBSD-${local.version_major}.${local.version_minor}-RELEASE-amd64-disc1.iso"
}

# image-related options
locals {
  boot_wait         = "10s"
  ssh_timeout       = "60m"
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
  vm_name          = "packer-freebsd-${local.version_major}.${local.version_major}-amd64"
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
    ["modifyvm", "{{ .Name }}", "--cpus", "${local.cpus}"]
  ]
  vm_name              = "packer-freebsd-${local.version_major}.${local.version_minor}-amd64"
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
      vagrantfile_template = "vagrantfile_templates/freebsd.rb"
    }
    post-processor "shell-local" {
      inline = [
        "bundle exec rake up",
        "bundle exec rake test",
      ]
    }
  }
}
