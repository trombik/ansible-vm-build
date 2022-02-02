
variable "compression_level" {
  type    = string
  default = "6"
}

variable "cpus" {
  type    = string
  default = "2"
}

variable "disk_size" {
  type    = string
  default = "40000"
}

variable "headless" {
  type    = string
  default = "true"
}

variable "iso_checksum" {
  type    = string
  default = "1882f9a23c9800e5dba3dbd2cf0126f552605c915433ef4c5bb672610a4ca3a4"
}

variable "iso_checksum_type" {
  type    = string
  default = "sha256"
}

variable "memory" {
  type    = string
  default = "512"
}

variable "mirror" {
  type    = string
  default = "http://cdn.openbsd.org/pub/OpenBSD"
}

variable "ssh_timeout" {
  type    = string
  default = "60m"
}

source "qemu" "autogenerated_1" {
  boot_command     = ["S<enter><wait>", "ifconfig vio0 inet autoconf<enter><wait10>", "ftp -o install.conf http://{{ .HTTPIP }}:{{ .HTTPPort }}/openbsd-7.0/install.conf<enter><wait>", "ftp -o install.sh http://{{ .HTTPIP }}:{{ .HTTPPort }}/openbsd-7.0/install.sh<enter><wait>", "ftp -o install-chroot.sh http://{{ .HTTPIP }}:{{ .HTTPPort }}/openbsd-7.0/install-chroot.sh<enter><wait>", "ftp -o disklabel.conf http://{{ .HTTPIP }}:{{ .HTTPPort }}/openbsd/disklabel.conf<enter><wait>", "sh install.sh < install-chroot.sh && reboot<enter>"]
  boot_wait        = "40s"
  disk_size        = "${var.disk_size}"
  headless         = "${var.headless}"
  http_directory   = "http"
  iso_checksum     = "${var.iso_checksum_type}:${var.iso_checksum}"
  iso_url          = "${var.mirror}/7.0/amd64/install70.iso"
  output_directory = "output-openbsd-7.0-amd64-${build.type}"
  qemuargs         = [["-m", "${var.memory}"], ["-smp", "${var.cpus}"]]
  shutdown_command = "sudo shutdown -h -p now"
  ssh_password     = "vagrant"
  ssh_timeout      = "${var.ssh_timeout}"
  ssh_username     = "vagrant"
  vm_name          = "packer-openbsd-7.0-amd64"
}

source "virtualbox-iso" "autogenerated_2" {
  boot_command         = ["S<enter><wait>", "ifconfig em0 inet autoconf<enter><wait10>", "ftp -o install.conf http://{{ .HTTPIP }}:{{ .HTTPPort }}/openbsd-7.0/install.conf<enter><wait>", "ftp -o install.sh http://{{ .HTTPIP }}:{{ .HTTPPort }}/openbsd-7.0/install.sh<enter><wait>", "ftp -o install-chroot.sh http://{{ .HTTPIP }}:{{ .HTTPPort }}/openbsd-7.0/install-chroot.sh<enter><wait>", "ftp -o disklabel.conf http://{{ .HTTPIP }}:{{ .HTTPPort }}/openbsd/disklabel.conf<enter><wait>", "sh install.sh < install-chroot.sh && reboot<enter>"]
  boot_wait            = "20s"
  disk_size            = "${var.disk_size}"
  guest_additions_mode = "disable"
  guest_os_type        = "OpenBSD_64"
  hard_drive_interface = "scsi"
  headless             = "${var.headless}"
  http_directory       = "http"
  iso_checksum         = "${var.iso_checksum_type}:${var.iso_checksum}"
  iso_url              = "${var.mirror}/7.0/amd64/install70.iso"
  output_directory     = "output-openbsd-7.0-amd64-${build.type}"
  post_shutdown_delay  = "30s"
  shutdown_command     = "sudo shutdown -h -p now"
  ssh_password         = "vagrant"
  ssh_timeout          = "${var.ssh_timeout}"
  ssh_username         = "vagrant"
  vboxmanage           = [["modifyvm", "{{ .Name }}", "--memory", "${var.memory}"], ["modifyvm", "{{ .Name }}", "--cpus", "${var.cpus}"]]
  vm_name              = "packer-openbsd-7.0-amd64"
}

build {
  sources = ["source.qemu.autogenerated_1", "source.virtualbox-iso.autogenerated_2"]

  provisioner "shell" {
    scripts = ["scripts/openbsd/init.sh", "scripts/common/vagrant.sh", "scripts/common/sshd.sh", "scripts/openbsd/minimize.sh"]
  }

  post-processor "vagrant" {
    compression_level    = "${var.compression_level}"
    output               = "openbsd-7.0-amd64-<no value>.box"
    vagrantfile_template = "vagrantfile_templates/openbsd.rb"
  }
}
