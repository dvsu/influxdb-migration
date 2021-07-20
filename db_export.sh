#!/bin/bash

# Replace the following variables with your values
# start_date, total_days, database_name, data_dir, wal_dir
# Output files will be stored in $HOME/db_export by default
start_date="September 15, 2020"
total_days=30
database_name="mydatabase"
data_dir="/var/lib/influxdb/data"
wal_dir="/var/lib/influxdb/wal"

day=0

cd /
if [ -d "$HOME/db_export" ] 
then
    echo "Directory $HOME/db_export exists. Start exporting data from database..." 
else
    echo "Directory $HOME/db_export does not exist. Creating new directory..."
    mkdir "$HOME/db_export"
    echo "Directory created. Start exporting data from database..."
fi

while [[ $day -lt $total_days ]] ;
do
    start_range="$start_date +$day days"
    end_range="$start_date +$(($day+1)) days"

    start=$(date --date "$start_range" -u +%Y-%m-%dT%H:%M:%SZ)
    end=$(date --date "$end_range" -u +%Y-%m-%dT%H:%M:%SZ)

    readarray -d T -t date_array <<< $start

    echo -n "${date_array[0]} "

    sudo influx_inspect export \
        -database $database_name \
        -datadir $data_dir \
        -waldir $wal_dir \
        -out "$HOME/db_export/backup_${date_array[0]}" \
        -start "$start" \
        -end "$end" && 
    sed -i '1,7d' "$HOME/db_export/backup_${date_array[0]}"

    day=$(($day+1))
done
