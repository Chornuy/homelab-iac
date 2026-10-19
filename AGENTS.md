# Agent Instructions

## Workflow

Before making any changes (editing files, running mutating commands, etc.), present a plan first and wait for explicit approval before executing.
## Documentation

Document operational changes in docs/ (inventory, network diagrams, procedures). Keep README accurate when workflows change.

## Ansible & IaC

- Keep secrets out of Git (use .tfvars, vault.yml)
- Prefer Ansible roles over ad-hoc shell commands
- Never commit .tfvars, *.pkrvars.hcl, SSH keys, or vault files

## Monitoring

Prometheus + Grafana on TrueNAS: all hosts + Proxmox PVE exporters must remain UP. Node Exporters run as Docker containers with restart_policy: always.
