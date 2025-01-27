# These are the commands we need to take care for running the project . 
cd vmware 
```
packer init debian.pkr.hcl

rm -rf debian | time PACKER_LOG=1 packer build debian.pkr.hcl

 sed -i '' 's/ethernet0.connectiontype = "nat"/ethernet0.connectiontype = "bridged"/' "debian/debian-12.8.vmx"

```

