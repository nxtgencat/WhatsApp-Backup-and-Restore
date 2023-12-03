#!/bin/bash

# Define color variables
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
CYAN="\e[36m"
RESET="\e[0m"

# Path to the whatsapp_directory to be backed up
whatsapp_directory="/storage/emulated/0/Android/media/com.whatsapp/WhatsApp"

# Path to the backup folder
backup_directory="/storage/emulated/0/.nxtgencat"

# Path to the restore folder
whatsappx_directory="/storage/emulated/0/Android/media/com.whatsapp/"

# Function to perform task A
backup() {
    # Check if the folder already exists
if [ ! -d "$backup_directory" ]; then
    # Create the backup folder
    mkdir "$backup_directory"
    if [ $? -eq 0 ]; then
        echo "\nBackup folder created successfully!"
    else
        echo "\nFailed to create the backup folder."
    fi
else
    echo "\nBackup folder already exists."
fi


# Array of file or whatsapp_directory names to be excluded from backup
exclude=("Backups" "Databases" "Media")

echo "\nPreparing A Clean Backup!"

# Iterate through all files and directories in the given whatsapp_directory
for file in "$whatsapp_directory"/.* "$whatsapp_directory"/*; do
    if [[ -f "$file" || -d "$file" ]]; then
        filename=$(basename "$file")

        # Exclude special whatsapp_directory references '.' and '..'
        if [[ "$filename" != "." && "$filename" != ".." ]]; then
            matched=false
            for item in "${exclude[@]}"; do
                # Check if the file or whatsapp_directory should be excluded
                if [[ "$filename" == "$item" ]]; then
                    matched=true
                    break
                fi
            done

            # If the file or whatsapp_directory is not in the exclude list, remove it
            if ! $matched; then
                rm -rf "$file"
            fi
        fi
    fi
done

echo "Cleaned Up!\n"


# Filename for the archive
archive_filename="whatsapp_archive"

# Variable to keep track of the archive number
archive_count=1

# Function to check if an archive file already exists
archive_exists() {
  if [ -e "$archive_filename.tar.gz" ]; then
    echo "Filename exists ($archive_filename)"
    echo "Updating Filename\n"
    return 0
  else
    echo "Generated Filename ($archive_filename)"
    echo "Archiving....\n"
    return 1
  fi
}

# Check if an archive file already exists
cd $backup_directory
while archive_exists; do
  archive_filename="whatsapp_archive$archive_count"
  archive_count=$((archive_count+1))
done

# Change to the parent whatsapp_directory of the target whatsapp_directory
cd "$(dirname "$whatsapp_directory")"

# Add .tar.gz extension to the archive filename
archive_filename="$archive_filename.tar.gz"

# Create the .tar.gz archive of the contents without the parent whatsapp_directory
tar -zcvf "$backup_directory/$archive_filename" -C "$(dirname "$whatsapp_directory")" "$(basename "$whatsapp_directory")/"*

# Output the archived file name
echo "\nArchiving Completed!"
echo "Backup Filename: $archive_filename\n"

}

# Function to perform task B
restore() {
echo
if [ ! -d "$backup_directory" ]; then
    echo "\nBackup Folder Not Found!"
    exit 0
else
   # Desired file extension
   file_extension=".tar.gz"

    # Change to the directory
    cd "$backup_directory" || exit

    # Find the latest file with the specified extension
    latest_file=$(ls -1t *"$file_extension" 2>/dev/null | head -n 1)
    
    # Check if the 'sus' folder exists
if [ ! -d "$whatsappx_directory" ]; then
  echo "Creating 'Media' folder..."
  mkdir -p "$whatsappx_directory"
fi

# Check if the 'com.whatsApp' folder exists
if [ ! -d "$whatsappx_directory" ]; then
  echo "Creating 'com.whatsApp' folder..."
  mkdir -p "$whatsappx_directory"
fi

echo "Restoring...."


    # Check if a valid file was found
    if [ -n "$latest_file" ]; then
    echo "\nLatest Backup File: $latest_file"
    # Extract the latest file to the WhatsApp directory
    tar -xzf "$latest_file" -C "$whatsappx_directory"
    echo "Latest Backup Fille Extracted! "
    else
    echo "\nNo Backup Files found in $backup_directory"
    fi
    
fi

}

# Function to display the menu and prompt for input
prompt() {
echo
    echo -e "${CYAN} ===== WhatsApp Tool ==== ${RESET}\n"
    echo -e "${GREEN} 1.Backup ${RESET}"
    echo -e "${YELLOW} 2.Restore ${RESET}"
    echo -e "${RED} 3.Quit ${RESET}\n"
    echo -n "${CYAN} Enter Choice:${RESET} "
    read -r choice

    case $choice in
        1)
            backup
            ;;
        2)
            restore
            ;;
        3)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo "Invalid choice. Please try again."
            echo
            prompt
            ;;
    esac
}

prompt
