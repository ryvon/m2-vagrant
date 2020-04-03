# M2 Vagrant

A Vagrant box for Magento 2 development.  Requires the VirtualBox provider.

## Installation

1. Install [Vagrant](https://www.vagrantup.com/)
2. Clone the repository
3. Configure `app/etc` and `etc/composer/auth.json`
4. Run `vagrant up` from the clone directory

If `MAGENTO_ARCHIVE` or `MAGENTO_SAMPLE_DATA_ARCHIVE` is defined but does not exist the provisioning script will attempt
to download the versions specified in `etc/env`.  To disable the download comment out the variables or ensure the
archives exist before provisioning.  Magento will be completely reinstalled with each `vagrant provision` command.

## If using WSL

Add to .bashrc:

```
export VAGRANT_WSL_ENABLE_WINDOWS_ACCESS="1"
export VAGRANT_WSL_WINDOWS_ACCESS_USER_HOME_PATH="/mnt/c/Users/Username/"
```

## License

[MIT](https://opensource.org/licenses/MIT)
