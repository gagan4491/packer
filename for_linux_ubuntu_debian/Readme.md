# These are the commands we need to take care for running the project . 
cd vmware 
```
packer init debian12.pkr.hcl

rm -rf output-vm | time PACKER_LOG=1 packer build debian12.pkr.hcl
```