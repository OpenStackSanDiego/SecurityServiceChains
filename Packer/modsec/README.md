# Building the Mod Security Image

This image was built in the same environment that the labs are run in and is using the OpenStack provider.

It seems packer likes these additional OpenStack variables:

```
export OS_TENANT_NAME=project16
export OS_DOMAIN_NAME=Default
export OS_KEY=/home/user16/.ssh/id_rsa
```

To build:

1. Edit the `modsec.json` file and add the correct network and image ID
1. Build the image

```
$ packer build modsec.json
```

Once the image has been built it can be downloaded.

```
$ openstack image save --file modsec.img ModSec
$ file modsec.img
modsec.img: QEMU QCOW Image (v3), 21474836480 bytes
```
