output "filename" {
  description = "Local path of the rendered snippet"
  value       = local_file.snippet.filename
}

output "uploaded_path" {
  description = "Path of the snippet on the Proxmox datastore"
  value       = "${var.proxmox_snippets_path}/snippets/${var.snippet_name}"
}
