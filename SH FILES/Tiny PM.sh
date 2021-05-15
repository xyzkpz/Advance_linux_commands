#!/bin/bash


# rwx=owner ---=group owner/others
umask 077

# variables 
GPG_OPTS="--quiet --yes --batch"
STORE_DIR="${HOME}/.password-store"

# abort func
abort() {
	printf '%s\n' "${1}" 1>&2
	exit 1
}

# encrypt func
gpg() {
	gpg2 $GPG_OPTS --default-recipient-self "$@"
}


readpw() {
	# Check user interaction, no daemons
	if [ -t 0 ]; then
		echo -n "${1}Password for ${entry_name}:"
		read -s password
		echo
	fi
}

# commands

# list command
list() {
	for line in `ls ~/.password-store | rev | cut -c 5- | rev`;  do echo $line; done
}

# show command
show() {
	entry_name="${1}"
	entry_path="${STORE_DIR}/${entry_name}.gpg"
	
	if [ -z "${entry_name}" ]; then
		abort "USAGE: tinyPassMan.sh show ENTRY"
	fi
	
	if [ ! -e "${entry_path}" ]; then
		abort "The requested entry does not exists!"
	fi
	
	gpg --decrypt "${entry_path}"
	
}

# insert command
insert() {
	entry_name="${1}"
	entry_path="${STORE_DIR}/${entry_name}.gpg"
	
	if [ -z "${entry_path}" ]; then
		abort "USAGE: tinyPassMan.sh insert ENTRYNAME"
	fi
	
	if [ -e "${entry_path}" ]; then
		abort "This entry already exists!"
	fi
	
	# read password from user
	readpw

	# This is very useful to check if a shell script is called by a real user using a terminal or if it was called by a crontab or a daemon (in this case the stdin won't exist).	
	if [ -t 0 ]; then
		printf '\n'
	fi
	
	if [ -z "${password}" ]; then
		abort "You did not specify a password"
	fi
	
	mkdir -p "${entry_path%/*}"
	printf '%s\n' "${password}" | gpg --encrypt --output "${entry_path}"
	
}

# Starting point
if [ $# -gt 2 ]; then
	abort "tinyPassMan.sh does not accept more than two arguments."
fi

if [ $# -lt 1 ]; then
	abort "tinyPassMan.sh COMMAND NAME"
fi

case "${1}" in
	"show") show "${2}" ;;
	"insert") insert "${2}" ;;
	"list") list ;;
	*) abort "USAGE: tinyPassMan.sh COMMAND NAME" ;;
esac
