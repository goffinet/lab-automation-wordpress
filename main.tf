provider "scaleway" {
  region       = "par1"
}

data "scaleway_image" "ubuntu" {
  architecture = "x86_64"
  name         = "Ubuntu Bionic"
}

resource "scaleway_server" "ubuntu" {
  count = 1
  name  = "wp-ubuntu-${count.index}"
  image = "${data.scaleway_image.ubuntu.id}"
  type  = "DEV1-S"
  dynamic_ip_required = true
  tags  = ["lab-automation-wordpress"]
  state = "running"
  provisioner "local-exec" {
    command = "while [ $(nc -z ${self.public_ip} 22 ; echo $?) == 1 ] ; do echo wait ; sleep 10 ; done ; scp -oStrictHostKeyChecking=no wordpress_setup.sh root@'${self.public_ip}':/root ; ssh -oStrictHostKeyChecking=no root@'${self.public_ip}' bash -x wordpress_setup.sh ; echo https://'${self.public_ip}'.nip.io >> sites.txt"
  }
}

data "scaleway_image" "centos" {
  architecture = "x86_64"
  name         = "CentOS 7.6"
}

resource "scaleway_server" "centos" {
  count = 1
  name  = "wp-centos-${count.index}"
  image = "${data.scaleway_image.centos.id}"
  type  = "DEV1-S"
  dynamic_ip_required = true
  tags  = ["lab-automation-wordpress"]
  state = "running"
  provisioner "local-exec" {
    command = "while [ $(nc -z ${self.public_ip} 22 ; echo $?) == 1 ] ; do echo wait ; sleep 10 ; done ; scp -oStrictHostKeyChecking=no wordpress_setup.sh root@'${self.public_ip}':/root ; ssh -oStrictHostKeyChecking=no root@'${self.public_ip}' bash -x wordpress_setup.sh ; echo https://'${self.public_ip}'.nip.io >> sites.txt"
  }
}

data "scaleway_image" "fedora" {
  architecture = "x86_64"
  name         = "Fedora 27"
}

resource "scaleway_server" "fedora" {
  count = 1
  name  = "wp-fedora-${count.index}"
  image = "${data.scaleway_image.fedora.id}"
  type  = "DEV1-L"
  dynamic_ip_required = true
  tags  = ["lab-automation-wordpress"]
  state = "running"
  provisioner "local-exec" {
    command = "while [ $(nc -z ${self.public_ip} 22 ; echo $?) == 1 ] ; do echo wait ; sleep 10 ; done ; scp -oStrictHostKeyChecking=no wordpress_setup.sh root@'${self.public_ip}':/root ; ssh -oStrictHostKeyChecking=no root@'${self.public_ip}' bash -x wordpress_setup.sh ; echo https://'${self.public_ip}'.nip.io >> sites.txt"  
  }
}
