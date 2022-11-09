#!/bin/bash

# Replace the following variables with your values
# start_date, total_days, database_name, data_dir, wal_dir
# Output files will be stored in $HOME/db_export by default
# change dayrange if you want to export x days into 1 backup-file (less files)
start_date="September 15, 2020"
total_days=30
database_name="mydatabase"
data_dir="/var/lib/influxdb/data"
wal_dir="/var/lib/influxdb/wal"
dayrange=1

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
    end_range="$start_date +$(($day+$dayrange)) days"

    if [ $(($day+$dayrange)) -gt $total_days ]
    then
      # endrage > total_days. shortened to total_days
      end_range="$start_date +$(($total_days)) days"
    fi;

    start=$(date --date "$start_range" -u +%Y-%m-%dT%H:%M:%SZ)
    end=$(date --date "$end_range" -u +%Y-%m-%dT%H:%M:%SZ)

    readarray -d T -t date_array <<< $start

    echo -n "${date_array[0]} (+$dayrange days) "

    sudo influx_inspect export \
        -database $database_name \
        -datadir $data_dir \
        -waldir $wal_dir \
        -out "$HOME/db_export/backup_${date_array[0]}" \
        -start "$start" \
        -end "$end" &&
    sed -i '1,7d' "$HOME/db_export/backup_${date_array[0]}"

    day=$(($day+$dayrange))
done
