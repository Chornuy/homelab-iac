resource "local_file" "snippet" {
  filename        = var.filename
  content         = templatefile(var.template_path, var.template_vars)
  file_permission = "0640"
}

resource "terraform_data" "upload" {
  triggers_replace = [md5(local_file.snippet.content)]

  connection {
    type        = "ssh"
    user        = var.ssh_user
    private_key = file(pathexpand(var.ssh_private_key_path))
    host        = var.proxmox_host
  }

  provisioner "remote-exec" {
    inline = ["mkdir -p ${var.proxmox_snippets_path}/snippets"]
  }

  provisioner "file" {
    source      = local_file.snippet.filename
    destination = "${var.proxmox_snippets_path}/snippets/${var.snippet_name}"
  }
}