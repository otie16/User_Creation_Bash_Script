#!/bin/bash

LOGFILE=/var/log/user_management.log
PASSWORD_FILE=/var/secure/user_passwords.txt


# A test case to check if the script is run by a root user
if [[ $EUID -ne 0 ]];
then
	echo "This script must be run as a root user"
	echo "Please log in as a root user to try again"
	exit 1
fi

# Checks if there is an argument passed when running the script
# That argument would be our text file containing the employee’s usernames and group names
if [ -z "$1" ];
then
	echo "This is how to use it: $0 <userlist-file>"
	exit 1
fi

# Here we create the required files for storing the logs and password
# Grant read and write permissions to the owner of the password file
mkdir -p /var/secure
touch $LOGFILE
touch $PASSWORD_FILE
chmod 600 $PASSWORD_FILE

# This is simple function to log messages and add timestamps
log_message() {
  echo "$(date +"%Y-%m-%d %T") : $1" >> $LOGFILE
}

# This is a function to create a user and groups
create_user_and_groups () {
	local username=$1
	local groups=$2
	
	# checking if user exist if not we create a user
	if id "$username" &>/dev/null;
	then
		log_message "User $username already exists."
	else
		useradd -m $username
		log_message "User $username created."
	
		# Creating a random password for our user
		password=$(openssl rand -base64 12)
   	        echo "$username:$password" | chpasswd
                echo "$username,$password" >> $PASSWORD_FILE
                log_message "Password for $username set."

                usermod -aG "$username" "$username"
                log_message "User $username added to group $username"
	fi
	
	 # Process and add the user to other groups
 	 IFS=',' read -ra ADDR <<< "$groups"
		for group in "${ADDR[@]}"; do
		group=$(echo "$group" | xargs)
		if ! getent group "$group" &>/dev/null; then
		groupadd "$group"
		log_message "Group $group created."
		fi
		usermod -aG "$group" "$username"
		log_message "User $username added to group $group."
	done
	}

# Read the input file line by line
while IFS=';' read -r username groups;
do
username=$(echo "$username" | xargs) 
groups=$(echo "$groups" | xargs) 
create_user_and_groups "$username" "$groups"
done < "$1"

echo "User creation process completed. Check $LOGFILE for details."



