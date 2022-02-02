variable "headless" {
  type    = string
  default = "false"
}

variable "mirror" {
  type    = string
  default = "http://cdn.openbsd.org/pub/OpenBSD"
}

# OS versions and ISO file
locals {
  version_major     = "7"
  version_minor     = "0"
  iso_checksum_type = "sha256"
  iso_checksum      = "1882f9a23c9800e5dba3dbd2cf0126f552605c915433ef4c5bb672610a4ca3a4"
  iso_url           = "${var.mirror}/7.0/amd64/install${local.version_major}${local.version_minor}.iso"
}

# image-related options
locals {
  ssh_timeout       = "60m"
  cpus              = "2"
  memory            = "1024"
  disk_size         = "40000"
  boot_wait         = "30s"
}

# auto-generated version
locals {
  box_version       = formatdate("YYYYMMDD.hhmm", timestamp())
}

source "qemu" "default" {
  boot_command     = [
    "S<enter><wait>",
    "ifconfig em0 inet autoconf<enter><wait10><wait10>",
    "ftp -o install.conf http://{{ .HTTPIP }}:{{ .HTTPPort }}/install.conf<enter><wait>",
    "ftp -o install.sh http://{{ .HTTPIP }}:{{ .HTTPPort }}/install.sh<enter><wait>",
    "ftp -o install-chroot.sh http://{{ .HTTPIP }}:{{ .HTTPPort }}/install-chroot.sh<enter><wait>",
    "ftp -o disklabel.conf http://{{ .HTTPIP }}:{{ .HTTPPort }}/disklabel.conf<enter><wait>",
    "sh install.sh < install-chroot.sh && reboot<enter>"
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
  shutdown_command = "sudo shutdown -p now"
  ssh_password     = "vagrant"
  ssh_timeout      = "${local.ssh_timeout}"
  ssh_username     = "vagrant"
  vm_name          = "packer-freebsd-${local.version_major}.${local.version_minor}-amd64"
}

source "virtualbox-iso" "default" {
  boot_command         = [
    "S<enter><wait>",
    "ifconfig em0 inet autoconf<enter><wait10><wait10>",
    "ftp -o install.conf http://{{ .HTTPIP }}:{{ .HTTPPort }}/install.conf<enter><wait>",
    "ftp -o install.sh http://{{ .HTTPIP }}:{{ .HTTPPort }}/install.sh<enter><wait>",
    "ftp -o install-chroot.sh http://{{ .HTTPIP }}:{{ .HTTPPort }}/install-chroot.sh<enter><wait>",
    "ftp -o disklabel.conf http://{{ .HTTPIP }}:{{ .HTTPPort }}/disklabel.conf<enter><wait>",
    "sh install.sh < install-chroot.sh && reboot<enter>"
  ]
  boot_wait            = "${local.boot_wait}"
  disk_size            = "${local.disk_size}"
  guest_additions_mode = "disable"
  guest_os_type        = "OpenBSD_64"
  hard_drive_interface = "scsi"
  headless             = "${var.headless}"
  http_directory       = "http"
  iso_checksum         = "${local.iso_checksum_type}:${local.iso_checksum}"
  iso_url              = "${local.iso_url}"
  output_directory     = "output/virtualbox-iso"
  post_shutdown_delay  = "30s"
  shutdown_command     = "sudo shutdown -p now"
  ssh_password         = "vagrant"
  ssh_timeout          = "${local.ssh_timeout}"
  ssh_username         = "vagrant"
  vboxmanage           = [
    ["modifyvm", "{{ .Name }}", "--memory", "${local.memory}"],
    ["modifyvm", "{{ .Name }}", "--cpus", "${local.cpus}"]
  ]
  vm_name              = "packer-openbsd-${local.version_major}.${local.version_minor}-amd64"
}

build {
  sources = ["source.qemu.default", "source.virtualbox-iso.default"]

  provisioner "shell" {
    scripts = [
      "scripts/init.sh",
      "scripts/vagrant.sh",
      "scripts/sshd.sh",
      "scripts/minimize.sh"
    ]
  }

  post-processors {
    post-processor "vagrant" {
      output               = "{{.Provider}}.box"
      vagrantfile_template = "vagrantfile_templates/openbsd.rb"
    }
    post-processor "shell-local" {
      inline = [
        "bundle exec rake up",
        "bundle exec rake test",
      ]
    }
  }
  post-processors {
    post-processor "vagrant" {
      output               = "{{.Provider}}.box"
      vagrantfile_template = "vagrantfile_templates/openbsd.rb"
    }
    post-processor "vagrant-cloud" {
      box_tag = "trombik/ansible-openbsd-${local.version_major}.${local.version_minor}-amd64"
      version = "${local.box_version}"
    }
    post-processor "shell-local" {
      inline = [
        "bundle exec rake clean",
      ]
    }
  }
}
