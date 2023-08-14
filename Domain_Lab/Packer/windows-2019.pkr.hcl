packer {
  required_plugins {
    windows-update = {
      version = "0.14.3"
      source  = "github.com/rgl/windows-update"
    }
  }
}

variable "disk_size" {
  type    = string
  default = "40960"
}

variable "iso_url" {
  type    = string
  default = "file:////home/shade/Documents/GoldenLab/Packer/Iso/Winser2019_eval.iso"
  #Or Download:
  #default = "https://software-static.download.prss.microsoft.com/sg/download/888969d5-f34g-4e03-ac9d-1f9786c66749/SERVER_EVAL_x64FRE_en-us.iso"
}

variable "iso_checksum" {
  type    = string
  default = "sha256:549BCA46C055157291BE6C22A3AAAED8330E78EF4382C99EE82C896426A1CEE1"
  #If downloaded from url:
  #default = "sha256:3e4fa6d8507b554856fc9ca6079cc402df11a8b79344871669f0251535255325"
}

source "virtualbox-iso" "windows-2019-amd64" {
  cpus      = 2
  memory    = 4096
  disk_size = var.disk_size
  floppy_files = [
    "scripts/floppy/provision-autounattend.ps1",
    "scripts/floppy/provision-openssh.ps1",
    "scripts/floppy/provision-psremoting.ps1",
    "scripts/floppy/provision-pwsh.ps1",
    "scripts/floppy/provision-winrm.ps1",
    "windows-2019/autounattend.xml",
  ]
  guest_additions_interface = "sata"
  guest_additions_mode      = "attach"
  guest_os_type             = "Windows2019_64"
  hard_drive_interface      = "sata"
  headless                  = true
  iso_url                   = var.iso_url
  iso_checksum              = var.iso_checksum
  iso_interface             = "sata"
  shutdown_command          = "shutdown /s /t 0 /f /d p:4:1 /c \"Packer Shutdown\""
  vboxmanage = [
    ["storagectl", "{{ .Name }}", "--name", "IDE Controller", "--remove"],
    ["modifyvm", "{{ .Name }}", "--vrde", "off"],
    ["modifyvm", "{{ .Name }}", "--graphicscontroller", "vboxsvga"],
    ["modifyvm", "{{ .Name }}", "--vram", "128"],
    ["modifyvm", "{{ .Name }}", "--accelerate3d", "on"],
    ["modifyvm", "{{ .Name }}", "--usb", "on"],
    ["modifyvm", "{{ .Name }}", "--mouse", "usbtablet"],
    ["modifyvm", "{{ .Name }}", "--audio", "none"],
    ["modifyvm", "{{ .Name }}", "--nictype1", "82540EM"],
    ["modifyvm", "{{ .Name }}", "--nictype2", "82540EM"],
    ["modifyvm", "{{ .Name }}", "--nictype3", "82540EM"],
    ["modifyvm", "{{ .Name }}", "--nictype4", "82540EM"],
  ]
  communicator             = "ssh"
  ssh_username             = "vagrant"
  ssh_password             = "vagrant"
  ssh_timeout              = "4h"
  ssh_file_transfer_method = "sftp"
}

build {
  sources = [
    "source.virtualbox-iso.windows-2019-amd64",
  ]

  provisioner "powershell" {
    use_pwsh = true
    script   = "scripts/provision/disable-windows-updates.ps1"
  }

  provisioner "powershell" {
    use_pwsh = true
    script   = "scripts/provision/disable-windows-defender.ps1"
  }

  provisioner "powershell" {
    use_pwsh = true
    only     = ["virtualbox-iso.windows-2019-amd64"]
    script   = "scripts/provision/virtualbox-prevent-vboxsrv-resolution-delay.ps1"
  }

  provisioner "windows-restart" {
  }

  provisioner "powershell" {
    use_pwsh = true
    script   = "scripts/provision/provision.ps1"
  }

  provisioner "windows-update" {
  }

  provisioner "powershell" {
    use_pwsh = true
    script   = "scripts/provision/enable-remote-desktop.ps1"
  }

  provisioner "powershell" {
    use_pwsh = true
    script   = "scripts/provision/eject-media.ps1"
  }

  provisioner "powershell" {
    use_pwsh = true
    script   = "scripts/provision/optimize.ps1"
  }

  post-processor "vagrant" {
    vagrantfile_template = "Vagrantfile.template"
  }
}
