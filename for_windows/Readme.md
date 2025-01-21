# These are the commands we need to take care for running the project . 
cd vmware 
```

$env:PACKER_LOG = "1"
packer init debian12.pkr.hcl
Remove-Item "output-vm" -Recurse -Force
packer build debian12.pkr.hcl
```
Remove-Item "output-vm" -Recurse -Force