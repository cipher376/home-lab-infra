#!/bin/bash

# Create role for terraform bot on proxmox
pveum role add TerraformRole -privs "VM.Allocate VM.Clone VM.Config.CDROM VM.Config.CPU VM.Config.Disk VM.Config.HWType VM.Config.Memory VM.Config.Network VM.Config.Options VM.PowerMgmt VM.Audit VM.Console  Datastore.AllocateSpace Datastore.Audit SDN.Use Sys.Audit Sys.Console"

#Create the user
pveum user add your-username@pve --password your-strong-password-here

# Give the user the permission
pveum aclmod / -user your-username@pve -role TerraformRole


# Escalate the privilege of the token so that terraform (workstation) can perform migrations
# 1. Create the role (if not already successful from the previous step)
pveum role add TerraformAdmin -privs "VM.Allocate VM.Clone VM.Config.CDROM VM.Config.CPU VM.Config.Cloudinit VM.Config.Disk VM.Config.HWType VM.Config.Memory VM.Config.Network VM.Config.Options VM.Audit VM.PowerMgmt VM.Migrate Datastore.AllocateSpace Datastore.Audit Sys.Audit Sys.Console Mapping.Use"

# 2. Assign the Role to the USER for the entire cluster (/)
pveum acl modify / -user your-username@pve -role TerraformAdmin

# 3. Assign the Role to the TOKEN for the entire cluster (/)
pveum acl modify / -token 'your-actual-token-uuid-here' -role TerraformAdmin