#!/bin/bash
packer init ubuntu24_04_server/packer.pkr.hcl
packer build -var-file variables.pkrvars.hcl ubuntu24_04_server/packer.pkr.hcl
