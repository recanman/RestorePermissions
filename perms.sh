#!/bin/bash
# The mountpoint that you messed up the permissions on.
NEW_PATH="$1"

# The backup mountpoint that has the original permissions.
BACKUP_PATH="$2"

echo -e "WARNING: The arguments MUST be absolute paths (/home/user/directory works, ~/directory DOES NOT)\n"

if [[ ! -d $NEW_PATH ]]; then
	echo "You must pass in the new path as the first argument (the mountpoint that has the messed up permissions)."
	exit 2
fi

if [[ ! -d $BACKUP_PATH ]]; then
	echo "You must pass in the backup path as the second argument (the mountpoint that has the correct permissions)."
	exit 2
fi

if [[ $EUID -ne 0 ]]; then
    echo "This script must run as root (use sudo)."
    exit 2
fi

function success {
	echo -e "\e[1;32m[+]\e[0m $1"
}

function error {
	echo -e "\e[1;31m[-]\e[0m $1" >&2
}

cd $NEW_PATH;
FILE_COUNT=$(find . -type f | wc -l)
let FILE_COUNT

if [ $FILE_COUNT == 0 ]; then
	error "There are no files in the new directory! Exiting."
	exit 2
else
	success "$FILE_COUNT file(s) found."
fi

files_checked=0

files_changed_permissions=0
files_changed_owner_uid=0
files_changed_owner_gid=0

files_nonexistent=0

function check_perms {
	backup_file="$BACKUP_PATH/$1"
	new_file="$NEW_PATH/$1"

	if [ "$1" == "." ]; then
		return
	fi

	if [ -e $backup_file ]; then
		let files_checked++
		success "File found! $backup_file ($files_checked/$FILE_COUNT)";

		backup_file_permissions=$(stat --format '%a' $backup_file)
		backup_file_owner_uid=$(stat -c '%u' $backup_file)
		backup_file_owner_gid=$(stat -c '%g' $backup_file)
		
		new_file_permissions=$(stat --format '%a' $new_file)
		new_file_owner_uid=$(stat -c '%u' $new_file)
		new_file_owner_gid=$(stat -c '%g' $new_file)

		if [ $backup_file_permissions != $new_file_permissions ] ; then
			error "=> \tFile does not have the same permissions! Setting permissions to $backup_file_permissions."
			chmod $backup_file_permissions $new_file;
			let files_changed_permissions++
		else
			success "=>\tFile has the same permissions."
		fi

		if [ $backup_file_owner_uid != $new_file_owner_uid ] ; then
			error "=>\tFile does not have the same owner! Setting owner to $backup_file_owner_uid."
			chown $backup_file_owner_uid $new_file;
			let files_changed_owner_uid++
		else
			success "=>\tFile has the same owner."
		fi

		if [ $backup_file_owner_gid != $new_file_owner_gid ] ; then
			error "=>\tFile does not have the same group owner! Setting group owner to $backup_file_owner_gid."
			chown :$backup_file_owner_gid $new_file;
			let files_changed_owner_gid++
		else
			success "=>\tFile has the same group permissions."
		fi
	else
		success "File does not exist ($new_file)!"
		let files_nonexistent++
	fi
}

while read -r file ; do
  check_perms "$file"
done < <(find .)

echo -e "\n"
success "DONE"

success "=>\t$files_changed_permissions file(s) had their permissions changed."
success "=>\t$files_changed_owner_uid file(s) had their user owner changed."
success "=>\t$files_changed_owner_gid file(s) had their group owner changed."
success "=>\t$files_nonexistent file(s) did not exist on the backup (the files are usually junk).";
