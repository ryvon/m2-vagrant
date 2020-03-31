# M2 Vagrant

A Vagrant box for Magento 2 development.  It expects the VirtualBox provider to be available.

## Installation

1. Install Vagrant
2. Configure `composer/auth.json` and `app/etc` 
3. Run `vagrant up`

Magento and the sample data will be downloaded during provisioning unless commented out in `etc/env`.  Magento will be reinstalled with each `vagrant provision` command run. 

## If using WSL

Add to .bashrc:

```
export VAGRANT_WSL_ENABLE_WINDOWS_ACCESS="1"
export VAGRANT_WSL_WINDOWS_ACCESS_USER_HOME_PATH="/mnt/c/Users/Username/"
```

## License

[MIT](https://opensource.org/licenses/MIT)
