# rhubarb-pi-debsig
The distributed packages should be signed to confirm the origin of the binary and that it has not been tampered with.

## For Debian based systems

Once installed the debsig-verify should identify the keys by short fingerprint.
```
# dpkg -i rhubarb-pi-debsig_1.0.27_all.deb
....
# debsig-verify rhubarb-pi-debsig_1.0.27_all.deb
debsig: Verified package from 'rhubarb-geek-nz@users.sourceforge.net' (rhubarb-geek-nz)
```

You now have the tools to verify the packages have not been tampered with.
