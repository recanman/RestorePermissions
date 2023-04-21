# RestorePermissions
A simple but handy script that restores permissions from a backup.

### Usage

This script must be run as root or with sudo.
The script takes two arguments only, the first being the directory with the incorrect permissions, and the second one being the one with the correct permissions.

**You must use absolute paths when referring to your directories (e.g `/home/user/directory` instead of `~/directory`**

Example:

```bash
sudo ./perms.sh /media/my_mountpoint_with_bad_permissions /media/my_backup
```

### Usecase

Here is an example of a situation in which this script would be useful:

1. You have an existing operating system that you transfer between two mediums of storage. You use `cp` to copy all files from the data partition to the new place.
2. You forget to use `cp -a`, and you lose all of your permissions and ownership.
3. You do not want to reinstall the system.

In this case, you would run the script with the first argument being the new storage medium, and the second argument being the initial copy/backup.
