detailed_summary(){
	clear
	echo -e "\nYou have selected [bii] View services summary\n"
	echo "===================================================="
	echo "[1] Hostname: $HOSTNAME"
	echo "===================================================="
	echo "[1.2] $(dig +dnssec osassignment.com)"
	echo "[1.3] $(dig +dnssec operating.com)"
	echo "===================================================="
	echo "[2] NFS service: $(service nfs-kernel-server status)"
	echo "===================================================="
	echo "[3] Remote access: $(sudo -S ufw status <<< "shepard")"
	echo "===================================================="
	echo -e "[4] MySQL:\n $(systemctl status mysql)"
	echo "===================================================="
	echo -e "[5] Remote Block Storage: \n$(sudo pvs -a)"
}

check_services(){
  while true; do
	clear
	echo "=============SERVICES AVAILABLE=============="
	echo "[1] Check DNS"
	echo "[2] Check Website"
	echo "[3] Check database"
	echo "[4] Check nfs storage"
	echo "[5] Check remote access"
	echo "[6] Check remote block storage"
	echo "[7] Main menu"
	echo "============================================="
	echo "select your choice"
	read choice

	case $choice in 
		1) check_dns ;;
		2) echo "Checking osassignment.com.."
		   check_website "www.osassignment.com"
		   sleep 1
		   echo "Checking operating.com..."
		   check_website "www.operating.com" ;;
		3) check_database "pravin" "Pravin@1234" "os" ;;
		4) check_nfs ;;
		5) check_remote_access ;;
		6) check_remote_block_storage ;;
		7) main_menu ;;
		*) echo "Invalid option" ;;
	esac

	read -n 1 -s -r -p $'\nPress any key to continue...'
  done
}

check_dns() {
  clear
  echo "You have selected [1] Check DNS"
  grep "log-queries" /etc/dnsmasq.conf && echo "DNS logging is configured" | less || echo "DNS logging is not configured"
}

check_website(){
	clear
	echo "You have selected [2] Check website"
	local website=$1

	curl -v -s "$website" > /dev/null

	if [ $? -eq 0 ]; then
		echo "Website $website is available."
	else
		echo "Website $website is unavailable."
	fi
}

check_database(){
	clear
	echo "You have selected [3] Check database"

	echo "Enter MySQL username: "
	read -p "> " username

	echo "Enter MySQL password: "
	read -s -p "> " password

	mysql -u "$username" -p"$password" -e "SELECT 1" 2>/dev/null

	if [ $? -eq 0 ]; then
	    echo "Logged in successfully!"

	    while true; do
		clear
		echo "========= MySQL Query Menu ======="
		echo "[1] Show Databases"
		echo "[2] List Tables in a Databases"
		echo "[3] Run Custom Query"
		echo "[4] Back"
		echo "=================================="

		read -p "Enter your choice: " choice

		case $choice in
		   1) mysql -u "$username" -p"$password" -e "SHOW DATABASES" ;;
		   2) echo "Enter database name: "
		      read -p "> " dbname
		      mysql -u "$username" -p"$password" -e "USE $dbname; SHOW TABLES" ;;
		   3) echo "Enter your custom query:"
		      read -p "> " custom_query
		      mysql -u "$username" -p"$password" -e "$custom_query" ;;
		   4) check_services ;;
		   *) echo "Invalid choice. Please enter a valid option." ;;
		 esac

		read -n1 -s -r -p $'\nPress any key to continue...'
	     done
	else
	   echo "Login failed. Incorrect username or password."
	fi
}

check_nfs(){
	clear
	echo "You have selected [4] Check NFS storage"
	nfs_server="172.16.129.5"
	nfs_share="/mnt/nfs_share"
	mount_point="/home/nfs"

	if [ ! -d "$mount_point" ]; then
		sudo mkdir -p "$mount_point" || { echo "Failed to create mount point"; exit 1; }
	fi

	sudo mount "$nfs_server:$nfs_share" "$mount_point"

	if [ $? -eq 0 ]; then
		echo "NFS is mounted successfully"
	else
		echo "NFS mount failed"
	fi
}

check_remote_access(){
   clear
   echo "You have selected [5] Check remote access"
   if ssh -v -p 2222 172.16.129.5 2>&1; then
	echo "Remote access check passed"
   else
	echo "Remote access check failed"
   fi
}

check_remote_block_storage(){
	clear
	echo "You have selected [6] Check remote block storage"
	result=$(sudo lvdisplay /dev/assignmentVG/assignmentLV 2>&1)

	if [ $? -eq 0 ]; then
	  sudo lvdisplay /dev/assignmentVG/assignmentLV 2>&1
	    echo "Volume exist, remote block storage check successful"
	else
	    echo "Volume does not exist"
	fi
}

disk_usage(){
	clear
        echo "You have selected [ci] Disk Usage"
	echo -e "Email will be send if disk space is more than 90%"
	echo -e "\n $(df -h --output=source,pcent)"

	disk_usage=$(df -h / | awk 'NR==2 {print $5}' | cut -d'%' -f1)

	threshold=90

	if [ $disk_usage -gt $threshold ]; then
		echo "Disk usage is above 90% on the server." | sendmail -v "Disk Usage Alert" osassignment.com
	else
		echo -e "\nDisk usage is below 90% on the server."
	fi
}

cpu_usage(){
	clear
	echo "You have selected [d] CPU usage"
	high_cpu=$(ps aux --sort=%cpu | awk '$3 >= 75 {print $0}')

	if [ -n "$high_cpu" ]; then
		echo "High CPU Usage (75% and above):"
		echo "high_cpu_process"
	else
		echo "No processes with high CPU usage found."
	fi
}

process_usage(){
	clear
	echo "You have selected [e] Process running identifier"
	long_process=$(ps -eo pid,etime,cmd | awk '$2 ~ /:[0-9][0-9]:[0-9][0-9]/ {print $0}')

	if [ -n "$long_process" ]; then
		echo -e "\nProcesses running for more than 1 hour:\n"
		echo "$long_process" | more
	else
		echo "No processes running for more than 1 hour found."
	fi
}

add_new_user(){
  clear
  echo "You have selected [f] Add a new user"
  local username=$1
  local default_password="abc123"

  if [[ -z "$username" || "$username" =~ ^[[:space:]]+$ ]]; then
	echo "Invalid username. Aborting."
	return
  fi

  if sudo id "$username" &>/dev/null; then
	echo "User $username already exists. Aborting."
  else
	sudo useradd -m -s /bin/bash "$username"

	if [ $? -eq 0 ]; then
		echo "$username:$default_password" | sudo chpasswd

		if [ $? -eq 0 ]; then
			echo "User $username added with a default password."
		else
			echo "Failed to set the password for user $username."
		fi
	else
		echo "Failed to add user $username."
	fi
  fi
}

add_users_from_list(){
   clear
   echo "You have selected [g] Add users from a name list"
   local userlist_file=$1
   local default_password="abcd123"

   while IFS= read -r username; do
	add_new_user "$username"
   done < "$userlist_file"
}

disable_user(){
	clear
	echo "You have selected [h] Disable a user"
	local username=$1

	read -p "Are you sure you want to disable user $username? (y/n): " choice
	if [ "$choice" = "y" ]; then
		sudo usermod --expiredate 1 $username
		echo "User $username disabled."
	else
		echo "Operation cancelled."
	fi
}

display_root_logins(){
	clear
	echo "You have selected [i] Display users who logged in as root for the past 7 days"
	echo "Users who logged in as root for the past 7 days with their commands: "
	local log_output
	seven_days_ago=$(date --date='7 days ago' '+%Y-%m-%d %H:%M:%S')
	log_output=$(sudo journalctl -u sudo.service | awk -v date="$seven_days_ago" '{if ($1 " " $2 " " $3 " " $4 >= date) print $1, $2, $3, $8, $10}' | sed 's/^/Command: /')

	if [ -z "$log_output" ]; then
		echo "No entries found in the past 7 days."
	else
		echo "$log_output"
	fi
}

generate_report(){
	clear
	echo "You have selected [j] generate report"
	report_file="report.txt"
	echo "Generating Report: "
	detailed_summary >> "$report_file"
	check_dns >> "$report_file"
	check_website >> "$report_file"
	check_nfs >> "$report_file"
	check_remote_access >> "$report_file"
	check_remote_block_storage >> "$report_file"
	disk_usage >> "$report_file"
	cpu_usage >> "$report_file"
	process_usage >> "$report_file"
	add_new_user "$new_username" >> "$report_file"
	add_users_from_list "$userlist_file" >> "$report_file"
	disable_user "$disable_username">> "$report_file"
	check_database >> "$report_file"
	echo -e "\nReport generated in $report_file"
}

main_menu(){
  while true; do
	clear
	echo "==============MAIN MENU============"
	echo "[bi] View services summary"
	echo "[bii] Check_services"
	echo "[ci]  Disk usage"
	echo "[d] CPU Usage"
	echo "[e] Process running identifier"
	echo "[f] Add a new user"
	echo "[g] Add users from a name list"
	echo "[h] Disable a user"
	echo "[i] Display users who logged in as root for the past 7 days"
	echo "[j] Generate report"
	echo "[k] Exit"
	echo "==================================="

	echo "Select your choice"
	read choice

	case $choice in
		bi)  detailed_summary | less ;;
		bii) check_services ;;
		ci)  disk_usage ;;
		d)   cpu_usage ;;
		e)   process_usage ;;
		f)   read -p "Enter the username for the new user: " new_username
		     add_new_user "$new_username" ;;
		g)   read -p "Enter the path to the user list file: " userlist_file
		     add_users_from_list "$userlist_file" ;;
		h)   read -p "Enter the username to disable: " disable_username
		     disable_user "$disable_username" ;;
		i)   display_root_logins ;;
		j)   generate_report ;;
		k)   exit ;;
	esac

	read -n 1 -s -r -p $'\nPress any key to continue...'
  done
}

main_menu
