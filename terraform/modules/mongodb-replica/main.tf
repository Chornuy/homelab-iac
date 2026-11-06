locals {
  seed_ip = element(split("/", var.nodes[var.seed_node].ip), 0)
}

resource "terraform_data" "mongo_cluster_init" {
  connection {
    type        = "ssh"
    user        = var.ssh_user
    private_key = file(pathexpand(var.ssh_private_key_path))
    host        = local.seed_ip
  }

  provisioner "remote-exec" {
    inline = [
      <<-EOT
      while [ ! -f /var/lib/cloud/instance/boot-finished ]; do sleep 5; done

      %{for name, node in var.nodes~}
      until nc -z -v -w5 ${element(split("/", node.ip), 0)} 27017; do echo 'Waiting for database interface on ${name}...'; sleep 5; done
      %{endfor~}

      mongosh --eval '
        rs.initiate({
          _id: "${var.replica_set_name}",
          members: [
            ${join(",\n            ", [
      for idx, name in keys(var.nodes) :
      "{ _id: ${idx}, host: \"${element(split("/", var.nodes[name].ip), 0)}:27017\" }"
])}
          ]
        })
      '
      echo "Waiting for ${var.seed_node} to be elected PRIMARY..."
      until mongosh --quiet --eval "db.hello().isWritablePrimary" | grep -q "true"; do
        echo "Still waiting for PRIMARY election status..."
        sleep 3
      done
      echo "Node is now PRIMARY. Safe to provision credentials."

      mongosh admin --eval '
        db.createUser({
          user: "${var.root_user}",
          pwd: "${var.root_password}",
          roles: [
            { role: "userAdminAnyDatabase", db: "admin" },
            { role: "readWriteAnyDatabase", db: "admin" },
            { role: "dbAdminAnyDatabase",   db: "admin" },
            { role: "clusterAdmin",         db: "admin" }
          ]
        })
      '

      echo "MongoDB Replica Set and Admin Authentication Provisioned Successfully."
      EOT
]
}
}

resource "terraform_data" "mongo_config_updater" {
  for_each = var.nodes

  triggers_replace = [md5(var.mongod_conf)]

  connection {
    type        = "ssh"
    user        = var.ssh_user
    private_key = file(pathexpand(var.ssh_private_key_path))
    host        = element(split("/", each.value.ip), 0)
  }

  provisioner "file" {
    content     = var.mongod_conf
    destination = "/tmp/mongod.conf"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mv /tmp/mongod.conf /etc/mongod.conf",
      "sudo chown root:root /etc/mongod.conf",
      "sudo chmod 0644 /etc/mongod.conf",
      "sudo systemctl restart mongod"
    ]
  }

  depends_on = [terraform_data.mongo_cluster_init]
}
