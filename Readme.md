# These are the commands we need to take care for running the project . 
cd vmware 
```
packer init debian.pkr.hcl

rm -rf debian | time PACKER_LOG=1 packer build debian.pkr.hcl
```