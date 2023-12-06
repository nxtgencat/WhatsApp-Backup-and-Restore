#!/bin/bash

whatsapp_directory="/storage/emulated/0/Android/medias/com.whatsapp/WhatsApp"
backup_directory="/storage/emulated/0/.nxtgencat"

# Function to log messages with timestamps
nxtgen_log() {
    local log_message="$1"
    local log_file="$backup_directory/nxtgen.log"
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")

    echo "[$timestamp] $log_message" >> "$log_file"
}

# Function to clear the screen and display the menu
clear_screen_and_menu() {
    clear
    echo
    echo -e "\e[96mWhatsAppTool\e[0m"
    echo "1. Backup"
    echo "2. Restore"
    echo "3. Cloud Backup"
    echo "4. Exit"
    echo
}

# Function to check if a directory exists and create it if not
create_directory_if_not_exists() {
    local directory_path="$1"

    if [ ! -d "$directory_path" ]; then
        nxtgen_log "Creating directory: $directory_path"
        mkdir -p "$directory_path"
    fi
}

# Function to remove files and folders except specified ones
remove_files_except() {
    local directory_path="$1"
    local exceptions=("Databases" "Media" "Backups")

    nxtgen_log "Removing files and folders in: $directory_path"
    
    for entry in "$directory_path"/* "$directory_path"/.*; do
        # Check if the entry is not in the exceptions list
        if [[ ! " ${exceptions[@]} " =~ " $(basename "$entry") " ]]; then
            rm -r "$entry" 2>/dev/null
        fi
    done
}

# Function to check if a directory is empty
is_directory_empty() {
    local directory_path="$1"

    if [ "$(ls -A "$directory_path")" ]; then
        return 1  # Directory is not empty
    else
        return 0  # Directory is empty
    fi
}

# Function to get the device model
get_device_model() {
    echo "$(getprop ro.product.model)"
}

# Function to get the next available counter for a specific archive name
get_next_counter() {
    local backup_directory="$1"
    local archive_name="$2"
    local counter=0

    while [ -e "$backup_directory/$archive_name$([ $counter -gt 0 ] && echo "_$counter").tar.gz" ]; do
        counter=$((counter + 1))
    done

    echo "$counter"
}

# Function to backup all folders into a single archive with device model and counter
backup_all_folders() {
    local source_directory="$1"
    local backup_directory="$2"
    local device_model

    device_model=$(get_device_model)
    archive_name="${device_model}_backup"

    counter=$(get_next_counter "$backup_directory" "$archive_name")

    nxtgen_log "Backing up all folders in: $source_directory"

    tar -czf "$backup_directory/$archive_name$([ $counter -gt 0 ] && echo "_$counter").tar.gz" -C "$source_directory/.." "$(basename "$source_directory")" || return 1

    echo "$archive_name$([ $counter -gt 0 ] && echo "_$counter").tar.gz"
}

# Function to handle errors during archive creation or restoration
handle_error() {
    local error_message="$1"
    nxtgen_log "Error: $error_message"
    echo -e "\e[91mError: $error_message\e[0m"
    return 1
}

# Function to get the file size in megabytes and kilobytes without using bc
get_file_size() {
    local file_path="$1"
    local size_in_bytes=$(stat -c %s "$file_path")

    if [ "$size_in_bytes" -ge $((1024 * 1024)) ]; then
        local size_in_megabytes=$((size_in_bytes / 1024 / 1024))
        local decimal_part=$((size_in_bytes * 100 / 1024 / 1024 % 100))
        echo "$size_in_megabytes.$(printf "%02d" $decimal_part) MB"
    else
        local size_in_kilobytes=$((size_in_bytes / 1024))
        echo "$size_in_kilobytes KB"
    fi
}

# Function for the backup option
backup_option() {
    create_directory_if_not_exists "$whatsapp_directory"
    remove_files_except "$whatsapp_directory"
    create_directory_if_not_exists "$backup_directory"
    
    if is_directory_empty "$whatsapp_directory"; then
        nxtgen_log "WhatsApp directory is empty. No backup created."
        echo -e "\e[93mWhatsApp directory is empty. No backup created.\e[0m"
    else
        local archive_name
        archive_name=$(backup_all_folders "$whatsapp_directory" "$backup_directory")
        
        if [ $? -eq 0 ]; then
            archive_path="$backup_directory/$archive_name"
            size=$(get_file_size "$archive_path")
            nxtgen_log "Backup completed successfully! Archive name: $archive_name, Size: $size"
            echo -e "\e[92mBackup completed successfully! \nArchive name: $archive_name, Size: $size\e[0m"
        else
            handle_error "Failed to create backup archive"
        fi
    fi

    # Return to the menu
}

# Function for the restore option
restore_option() {
    local latest_archive
    local whatsapp_backup_directory="$backup_directory" # Change this if your backup directory structure is different

    # Find the latest archive
    latest_archive=$(find "$whatsapp_backup_directory" -type f -name '*.tar.gz' | sort -V | tail -n 1)

    if [ -z "$latest_archive" ]; then
        nxtgen_log "No backup archives found. Restore aborted."
        echo -e "\e[93mNo backup archives found. Restore aborted.\e[0m"
        return
    fi

    archive_path="$latest_archive"
    archive_size=$(get_file_size "$archive_path")

    nxtgen_log "Restoring from the latest backup archive: $latest_archive, Size: $archive_size"

    # Extract contents of the root folder from the latest archive to WhatsApp directory
    tar -xzf "$latest_archive" -C "$whatsapp_directory" --strip-components=1

    if [ $? -eq 0 ]; then
        nxtgen_log "Restore completed successfully! Archive name: $(basename "$latest_archive"), Size: $archive_size"
        echo -e "\e[92mRestore completed successfully! \nArchive name: $(basename "$latest_archive"), Size: $archive_size\e[0m"
    else
        handle_error "Failed to extract contents from the backup archive"
    fi

    # Return to the menu
}

# Function for the cloud backup option
cloud_backup_option() {
    url="https://devuploads.com/api/upload/server"
    api_key="19072fnpbaqn165zzev01"
    server_url=""
    sess_id=""
    file_path=""
    echo -e "\e[92mConnecting to server....\e[0m"
    # Fetch session ID and server URL
    if [ -z "$sess_id" ]; then
        api_key="${api_key:-your_constant_api_key}"
        res_json=$(curl -s -X GET "$url?key=$api_key")
        res_status=$(echo "$res_json" | grep -o '"status":[0-9]*' | awk -F ':' '{print $2}')
        sess_id=$(echo "$res_json" | grep -o '"sess_id":"[^"]*"' | awk -F ':' '{print $2}' | tr -d '"')
        server_url=$(echo "$res_json" | sed -n 's/.*"result":"\([^"]*\).*/\1/p')

        if [ "$res_status" -ne 200 ]; then
            nxtgen_log "Invalid API KEY $api_key"
            echo "Invalid API KEY $api_key"
            exit 1
        fi
    fi

    # Find the latest archive in the backup directory
    latest_archive=$(find "$backup_directory" -type f -name '*.tar.gz' | sort -V | tail -n 1)

    if [ -z "$latest_archive" ]; then
        nxtgen_log "No backup archives found. Cloud Backup aborted."
        echo -e "\e[93mNo backup archives found. Cloud Backup aborted.\e[0m"
        exit 1
    fi

    archive_name=$(basename "$latest_archive")  # Extracting archive name from the path
    archive_path="$latest_archive"
    archive_size=$(get_file_size "$archive_path")
    file_path="$latest_archive"

    # Validate file path
    if [ ! -f "$file_path" ]; then
        nxtgen_log "File $file_path not found"
        echo "File $file_path not found"
        exit 1
    fi

    # Print checks
    nxtgen_log "✓ API key is valid."
    nxtgen_log "✓ Tokens fetched."
    nxtgen_log "✓ File path is valid."

    # Upload file
    url="${server_url:-$url}"
    echo -e "\e[92mUploading file ....\e[0m"
    echo -e "\e[92mArchive name: $archive_name, Size: $archive_size\e[0m\n"

    res_file_name="u$(head -c 32 /dev/urandom | base64 | tr -d '+/=')json"
    curl -X POST -o "$res_file_name" -F "sess_id=$sess_id" -F "utype=reg" -F "file=@$file_path" "$url" || {
        nxtgen_log "Error uploading file."
        echo "Error uploading file."
        rm "$res_file_name"  # Clean up the temporary response file
        exit 1
    }

    # Get file code using awk
    file_code=$(awk -F'"' '/file_code/{print $4}' "$res_file_name")
    rm "$res_file_name"
    
    # Print file information for cloud backup
    prefix_url="https://devuploads.com/"
    nxtgen_log "File uploaded successfully! \nFile code: $file_code \nLink : $prefix_url$file_code"
    echo
    echo -e "\e[92mFile uploaded successfully! \nFile code: $file_code \nLink : $prefix_url$file_code\e[0m\n"

    # If cloud backup completed successfully
    if [ $? -eq 0 ]; then
        nxtgen_log "Cloud Backup completed successfully! Archive name: $archive_name, Size: $archive_size"
        echo -e "\e[92mCloud Backup completed successfully! \n\e[0m"
    else
        handle_error "Failed to create cloud backup"
    fi
}

# WhatsAppTool Menu
clear_screen_and_menu

while true; do
    echo
    read -p "Enter your choice (1-4): " choice

    case $choice in
        1)  clear_screen_and_menu
            backup_option ;;
        2)  clear_screen_and_menu
            restore_option ;;
        3)  clear_screen_and_menu
            cloud_backup_option ;;
        4)  echo -e "\e[92m\nExiting WhatsAppTool. Goodbye!\e[0m\n"
            exit ;;
        *)  nxtgen_log "Invalid choice. Please enter a number between 1 and 4."
            echo -e "\e[91mInvalid choice. Please enter a number between 1 and 4.\e[0m" ;;
    esac
done
