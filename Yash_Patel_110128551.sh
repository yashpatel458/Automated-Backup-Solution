#!/bin/bash

# Define the main directories for backups and logs
backup_dir=$HOME/home/backup
complete_backup_dir=${backup_dir}/cbw24
incremental_backup_dir=${backup_dir}/ib24
differential_backup_dir=${backup_dir}/db24
log_file=${backup_dir}/backup.log
username="yashpatel"  # Username for the home directory to backup

# Initialize counters for naming backup files
complete_counter=1
incremental_counter=1
differential_counter=1

# Ensure backup directories exist, create them if not
mkdir -p "$complete_backup_dir"
mkdir -p "$incremental_backup_dir"
mkdir -p "$differential_backup_dir"

# Function to create a complete backup of all user files
function complete_backup() {
    # Generate the complete backup file name with a counter
    local tar_file_name="cbw24-${complete_counter}.tar"
    # Create a tarball of all files in the user's home directory, excluding the backup directory and hidden files
    tar -cvpf ${complete_backup_dir}/${tar_file_name} --exclude=${backup_dir} --exclude="/home/${username}/.*" /home/${username}/
    # Log the backup operation
    echo "$(date +"%a %d %b %Y %I:%M:%S %p %Z") ${tar_file_name} was created" >> ${log_file}
    # Increment the complete backup counter
    ((complete_counter++))
}

# Function to create an incremental backup of recently modified files
function incremental_backup() {
    # Get the reference time from the function argument
    local reference_time=$1
    # Generate the incremental backup file name with a counter
    local tar_file_name="ibw24-${incremental_counter}.tar"
    # Find and backup files modified since the last backup, excluding the backup directory and hidden files
    find /home/${username}/ -type f -newermt "${reference_time}" ! -path "${backup_dir}/*" ! -path "/home/${username}/.*/*" ! -name ".*" -print0 | tar -cvpf ${incremental_backup_dir}/${tar_file_name} --null -T -
    # Check if the tar file contains any files, indicating changes
    if [ $(tar -tvf ${incremental_backup_dir}/${tar_file_name} | wc -l) -gt 0 ]; then
        # Log the creation of the incremental backup
        echo "$(date +"%a %d %b %Y %I:%M:%S %p %Z") ${tar_file_name} was created" >> ${log_file}
        # Increment the incremental backup counter
        ((incremental_counter++))
    else
        # Log that no incremental backup was needed
        echo "$(date +"%a %d %b %Y %I:%M:%S %p %Z") No changes - Incremental backup was not created" >> ${log_file}
        # Remove the empty tar file
        rm ${incremental_backup_dir}/${tar_file_name}
    fi
}

# Function to create a differential backup of files changed since the last complete backup
function differential_backup() {
    # Get the reference time from the function argument
    local reference_time=$1
    # Generate the differential backup file name with a counter
    local tar_file_name="dbw24-${differential_counter}.tar"
    # Find and backup files modified since the last complete backup, excluding the backup directory and hidden files
    find /home/${username}/ -type f -newermt "${reference_time}" ! -path "${backup_dir}/*" ! -path "/home/${username}/.*/*" ! -name ".*" -print0 | tar -cvpf ${differential_backup_dir}/${tar_file_name} --null -T -
    # Check if the tar file contains any files, indicating changes
    if [ $(tar -tvf ${differential_backup_dir}/${tar_file_name} | wc -l) -gt 0 ]; then
        # Log the creation of the differential backup
        echo "$(date +"%a %d %b %Y %I:%M:%S %p %Z") ${tar_file_name} was created" >> ${log_file}
        # Increment the differential backup counter
        ((differential_counter++))
    else
        # Log that no differential backup was needed
        echo "$(date +"%a %d %b %Y %I:%M:%S %p %Z") No changes - Differential backup was not created" >> ${log_file}
    fi
}

# Main loop to periodically execute the backup functions
last_backup_time=$(date +"%Y-%m-%d %H:%M:%S")
while true; do
    # Record the time of the complete backup
    complete_backup_time=$(date +"%Y-%m-%d %H:%M:%S")
    # Perform a complete backup
    complete_backup
    last_backup_time=$(date +"%Y-%m-%d %H:%M:%S")  # Update the last backup time


    # Wait for 2 minutes before the next operation
    sleep 120
    # Perform an incremental backup using the last backup time as the reference
    incremental_backup "${last_backup_time}"
    # Update the last backup time for the next incremental backup
    last_backup_time=$(date +"%Y-%m-%d %H:%M:%S")

    # Wait for 2 minutes before the next operation
    sleep 120
    # Perform another incremental backup
    incremental_backup "${last_backup_time}"
    # Update the last backup time again
    last_backup_time=$(date +"%Y-%m-%d %H:%M:%S")

    # Wait for 2 minutes before the next operation
    sleep 120
    # Perform a differential backup using the time of the last complete backup as the reference
    differential_backup "${complete_backup_time}"
    # Update the last backup time for the next operation
    last_backup_time=$(date +"%Y-%m-%d %H:%M:%S")

    # Wait for 2 minutes before starting the loop again
    sleep 120
    # Perform another incremental backup before the loop restarts
    incremental_backup "${last_backup_time}"
    # Update the last backup time once more
    last_backup_time=$(date +"%Y-%m-%d %H:%M:%S")

    # Wait for 2 minutes before repeating the entire backup process
    sleep 120
done