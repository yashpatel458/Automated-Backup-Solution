#!/bin/bash
# Variables
backup_dir=$HOME/home/backup
complete_backup_dir=${backup_dir}/cbw24
incremental_backup_dir=${backup_dir}/ib24
differential_backup_dir=${backup_dir}/db24
log_file=${backup_dir}/backup.log
username="yashpatel"  # Set to the actual username

# Create directories if they don't exist
mkdir -p "$complete_backup_dir"
mkdir -p "$incremental_backup_dir"
mkdir -p "$differential_backup_dir"

# Function to create a complete backup
function complete_backup() {
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    local tar_file_name="cbw24-$(date +%s).tar"
    tar -cvpf ${complete_backup_dir}/${tar_file_name} --exclude=${backup_dir} --exclude="/home/${username}/.*" /home/${username}/
    echo "$(date +"%a %d %b %Y %I:%M:%S %p %Z") ${tar_file_name} was created" >> ${log_file}
}

# Function to create an incremental backup
function incremental_backup() {
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    local reference_time=$1
    local tar_file_name="ibw24-$(date +%s).tar"
    find /home/${username}/ -type f -newermt "${reference_time}" ! -path "${backup_dir}/*" ! -path "/home/${username}/.*/*" ! -name ".*" -print0 | tar -cvpf ${incremental_backup_dir}/${tar_file_name} --null -T -
    if [ $(tar -tvf ${incremental_backup_dir}/${tar_file_name} | wc -l) -gt 0 ]; then
        echo "$(date +"%a %d %b %Y %I:%M:%S %p %Z") ${tar_file_name} was created" >> ${log_file}
    else
        echo "$(date +"%a %d %b %Y %I:%M:%S %p %Z") No changes - Incremental backup was not created" >> ${log_file}
        rm ${incremental_backup_dir}/${tar_file_name}  # Remove the empty tar file
    fi
}

# Function to create a differential backup
function differential_backup() {
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    local reference_time=$1
    local tar_file_name="dbw24-$(date +%s).tar"
    find /home/${username}/ -type f -newermt "${reference_time}" ! -path "${backup_dir}/*" ! -path "/home/${username}/.*/*" ! -name ".*" -print0 | tar -cvpf ${differential_backup_dir}/${tar_file_name} --null -T -
    if [ $(tar -tvf ${differential_backup_dir}/${tar_file_name} | wc -l) -gt 0 ]; then
        echo "$(date +"%a %d %b %Y %I:%M:%S %p %Z") ${tar_file_name} was created" >> ${log_file}
    else
        echo "$(date +"%a %d %b %Y %I:%M:%S %p %Z") No changes - Differential backup was not created" >> ${log_file}
    fi
}

# Main loop
last_backup_time=$(date +"%Y-%m-%d %H:%M:%S")
while true; do
    complete_backup_time=$(date +"%Y-%m-%d %H:%M:%S")
    complete_backup

    sleep 30
    incremental_backup "${last_backup_time}"
    last_backup_time=$(date +"%Y-%m-%d %H:%M:%S")  # Update the last backup time

    sleep 30
    incremental_backup "${last_backup_time}"
    last_backup_time=$(date +"%Y-%m-%d %H:%M:%S")  # Update the last backup time

    sleep 30
    differential_backup "${complete_backup_time}"

    sleep 30
    incremental_backup "${last_backup_time}"
    last_backup_time=$(date +"%Y-%m-%d %H:%M:%S")  # Update the last backup time

    sleep 30
done
