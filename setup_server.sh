#!/bin/bash

# Program to set up my Linux server environment

##### Variables
USERNAME="saintwolf"	# Default username
EMAIL="judiconis@gmail.com"

##### Functions

function setup_user
{
	# Sets up the primary user for the system
	echo -n "Enter the name for your new user: "
	read USERNAME
	echo -n "Enter the e-mail address of your user: "
	read EMAIL

	# Add User
	adduser -gecos "" $USERNAME

	# Create SSH directories/files
	mkdir /home/$USERNAME/.ssh
	chmod 700 /home/$USERNAME/.ssh
	touch /home/$USERNAME/.ssh/authorized_keys
	chmod 600 /home/$USERNAME/.ssh/authorized_keys

	# Set SSH security config
	sed -i 's/^PermitRootLogin.*$/PermitRootLogin no/g' /etc/ssh/sshd_config

	# Install and setup sudo
	apt-get install -y sudo
	# Add user to sudoers file, user will not have to confirm their password for root access
	# consider setting up a SSH key
	echo "$USERNAME ALL=(ALL:ALL) NOPASSWD:ALL" | (EDITOR="tee -a" visudo)
	
	echo "WARNING: USER WILL NOT HAVE TO CONFIRM PASSWORD FOR SUDO ROOT ACCESS"
	echo "IT IS HIGHLY RECOMMENDED THAT YOU DISABLE PASSWORD AUTHENTICATION VIA SSH"
	echo "AND USE PUBLIC KEYS INSTEAD!!!!"
}

function setup_security_apps
{
	# Sets up the core apps required for server security

	# Update System
	apt-get update
	apt-get upgrade -y

	# Install and setup fail2ban
	apt-get install -y fail2ban
	# Configure fail2ban
	cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
	sed -i '/\[ssh-ddos\]/,/enabled =.*/{s/enabled.*/enabled = true/g}' /etc/fail2ban/jail.local
	sed -i '/\[apache\]/,/enabled =.*/{s/enabled.*/enabled = true/g}' /etc/fail2ban/jail.local
	sed -i '/\[apache-noscript\]/,/enabled =.*/{s/enabled.*/enabled = true/g}' /etc/fail2ban/jail.local
	sed -i '/\[apache-overflows\]/,/enabled =.*/{s/enabled.*/enabled = true/g}' /etc/fail2ban/jail.local
	
	# Install and set up RKHunter
	apt-get install -y rkhunter
	# Configure RKHunter
	sed -i "s,^SCRIPTWHITELIST=/usr/bin/lwp-request$,#&,g" /etc/rkhunter.conf # Fix bug in config file
	# Cron Jobs
	echo "0 0 * * * rkhunter --update" | tee -a /var/spool/cron/crontabs/root
	echo "1 0 * * * rkhunter -c --cronjob 2>&1 | mail -s \"RKHunter Scan Details - $HOSTNAME\" $EMAIL" | tee -a /var/spool/cron/crontabs/root
	
	# Install and setup logwatch
	apt-get install -y logwatch
	# Configure Logwatch
	sed -i "s/^Output.*$/Output = mail/g" /usr/share/logwatch/default.conf/logwatch.conf
	sed -i "s/^Format.*$/Format = html/g" /usr/share/logwatch/default.conf/logwatch.conf
	sed -i "s/^MailTo.*$/MailTo = $EMAIL/g" /usr/share/logwatch/default.conf/logwatch.conf
	sed -i "s/^MailFrom.*$/MailFrom = logwatch@$HOSTNAME/g" /usr/share/logwatch/default.conf/logwatch.conf
	sed -i "s/^Detail.*$/Detail = Med/g" /usr/share/logwatch/default.conf/logwatch.conf
	# Cron jobs
	echo "0 1 * * * logwatch" | tee -a /var/spool/cron/crontabs/root
}

function setup_lamp_server
{
	# Sets up Apache2, MySQL and PHP
	apt-get install -y apache2 php5-mysql mysql-server php5 libapache2-mod-php5

	# Do Apache stuff
	mkdir /var/virtualsites
	chown www-data:www-data /var/virtualsites

	# Disable InnoDB
	sed -i 's/\[mysqld\]/&\nskip-innodb\ndefault-storage-engine = myisam/g' /etc/mysql/my.cnf
	/etc/init.d/mysql restart
}

# Main
echo ""

selection=
until [ "$selection" = "0" ]
do
	echo "----------------------------------"
	echo "---Welcome to the setup script!---"
	echo "-----------By Saintwolf-----------"
	echo "--------DEBIAN 7/8 ONLY!!!--------"
	echo "----------------------------------"
	echo "Please selection an option:"
	echo ""
	echo "1) Setup Admin User"
	echo "2) Setup Security Apps"
	echo "3) Setup LAMP server"
	echo ""
	echo "0) Exit"
	echo -n "Enter selection: "
	read selection
	echo ""
	case $selection in
		1 ) setup_user ;;
		2 ) setup_security_apps ;;
		3 ) setup_lamp_server ;;
		0 ) exit ;;
		* ) echo "Please enter a valid option!"
	esac
done
