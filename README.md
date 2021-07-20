# InfluxDB Migration

An easy, step-by-step guide to migrate InfluxDB data from legacy (1.x) to new version (2.x)

## What You Need to Know

Before we get started, there are a few things you need to know

1. Version 1.x and 2.x have different `.manifest` file format. It means the standard `influx backup` and `influx restore` flow will not work.
2. The backup file may be huge, depending on the target time range and datapoints. It may be wise to export data from old database and split it into several files.
3. The data from old database cannot be stored in the existing `bucket`. New bucket is required.

## Get Started

### Step 1: Export Data from Old Database (v1.x)

Dump all data, or selected database to file in line-protocol format using `influx_inspect export`

`influx_inspect export` have a few options that are commonly used:

- `-compress`
- `-database`
- `-datadir`
- `-waldir`
- `-out`
- `-start`
- `-end`

For details, please see <https://docs.influxdata.com/influxdb/v1.8/tools/influx_inspect/#export>

#### `-compress`

The output format, whether or not it is compressed. Default value is `false`

#### `-database`

The name of database that wants to be exported. Default value is `""`

**_Example_**

If we want to export data from database `officeserver`, then the `-database` value is

```none
-database "officeserver"
```

#### `-datadir`

Directory of the target database.  
`-datadir` has default value of `"$HOME/.influxdb/data"`  
In some cases, the actual `-datadir` may differ from the default value.

The full InfluxDB configuration is stored in `influxdb.conf`

```shell
cat /etc/influxdb/influxdb.conf
```

Check the `[data]` section and find `dir` to get the actual data directory.  
The value may look like this

```none
[data]
  # The directory where the TSM storage engine stores TSM files.
  dir = "/var/lib/influxdb/data"
  ...
```

**_Note_**

If you are unsure, how many databases, or the available database, you can check it at `dir` directory

**_Example_**

```none
ls /var/lib/influxdb/data
```

**_Example of output_**

```none
database1 database2 officeserver _internal
```

#### '-waldir'

Similarly, the WAL directory also has default value of `"$HOME/.influxdb/wal"`

Double check the actual WAL directory in `influxdb.conf` file.  
The value may be different and look like this

```none
[data]
  ...
  # The directory where the TSM storage engine stores WAL files.
  wal-dir = "/var/lib/influxdb/wal"
  ...
```

#### `-out`

The name of output file.

**_Example_**

If the name is `backup_data` and the designated directory is `/home/ubuntu/output`
then `-out` value is

```none
-out /home/ubuntu/output/backup_data
```

#### `-start`

The start of time range and must be in RFC3339 format, such as YYYY-MM-DDTHH:MM:SSZ

**_Example_**

If the start of time range is 12 May 2021, 08:30:00 UTC time, then the expected value is

```none
-start 2021-05-12T08:30:00Z
```

#### `-end`

The end of time range and must be in RFC3339 format, such as YYYY-MM-DDTHH:MM:SSZ

**_Example_**

Similar to `start`, if the end of time range is 30 June 2021, 23:45:00 UTC time, then the expected value is

```none
-end 2021-06-30T23:45:00Z
```

#### Exporting Data: Full Example

Target_database `"officeserver"`  
Database directory `"/var/lib/influxdb/data"`  
WAL directory `"/var/lib/influxdb/wal"`  
Output filename including directory path `"/home/ubuntu/migrate/backup_data"`

```none
sudo influx_inspect export -database "officeserver" -datadir "/var/lib/influxdb/data" -waldir "/var/lib/influxdb/wal" -out "/home/ubuntu/migrate/backup_data"
```

**_Notes_**

1. You may be required to use `sudo` to give you permission to export data from the database.
2. If data is huge, please consider adding `-start` and `-end` options, plus new `-out` option value to dump the export to different file, i.e. to prevent overwriting.

**_Example_**

Exporting data from database into several files, separated by date.

First export (12 May 2021)

```none
sudo influx_inspect export -database "officeserver" -datadir "/var/lib/influxdb/data" -waldir "/var/lib/influxdb/wal" -out "/home/ubuntu/migrate/backup_data_20210512" -start "2021-05-12T00:00:00Z" -end "2021-05-13T00:00:00Z"
```

Second export (13 May 2021)

```none
sudo influx_inspect export -database "officeserver" -datadir "/var/lib/influxdb/data" -waldir "/var/lib/influxdb/wal" -out "/home/ubuntu/migrate/backup_data_20210513" -start "2021-05-13T00:00:00Z" -end "2021-05-14T00:00:00Z"
```

Alternatively, `db_export.sh` may also be used to perform the automatic export.  
Replace the following variables with the right values.

- `start_date`
- `total_days`
- `database_name`
- `data_dir`
- `wal_dir`

Next, make the file executable and run it. Output files will be stored in `$HOME/db_export` by default.

```none
sudo chmod +x db_export.sh
./db_export.sh
```

### Step 2: Transfer Data

If the new InfluxDB is located in different machine, data should be transferred prior to writing. Otherwise, skip this step.

### Step 3: Create New Bucket

As mentioned in previous part, the data from old database has to stored in new bucket.  
The easiest way to create new bucket is though web interface.
In general, it may be accessible via `localhost` at port `8086`. If specific IP is used, e.g. public IP address, substitute the `localhost` with the IP address.

**_Example_**

```none
http://localhost:8086
```

or

```none
http://12.34.56.78:8086
```

After login, navigate to

```none
Data -> Buckets -> Create Bucket
```

### Step 4: Write Data to New Database

Assuming the data has been transferred and InfluxDB 2.x has been installed on new machine, one of the cleanest ways to execute the write command is by creating a shell script.

Before we create the script, we require

1. `org` organization name
2. `bucket` the name of newly created bucket
3. `token` InfluxDB access token

All of them can be obtained through InfluxDB 2.x web interface.

Next, let's create the script and name it, for example, `migrate_influxdb.sh`. Inside the file, it should have the following structure.

```shell
#!/bin/sh

influx write \
  --org org_name \
  --bucket new_bucket_name \
  --token token_value \
  --file /path/to/backup/data
```

If you have multiple files, the command should look like this.

```shell
#!/bin/sh

influx write \
  --org org_name \
  --bucket new_bucket_name \
  --token token_value \
  --file /path/to/backup/data_1
  --file /path/to/backup/data_2
  --file /path/to/backup/data_3
  --file /path/to/backup/data_4
  --file /path/to/backup/data_5
```

Then, make the script executable

```shell
sudo chmod +x migrate_influxdb.sh
```

For details, please see <https://docs.influxdata.com/influxdb/v2.0/reference/cli/influx/write/#write-line-protocol-from-multiple-files>

#### Writing Data: Full Example

```shell
#!/bin/sh

influx write \
  --org my_org \
  --bucket my_new_bucket \
  --token 1a2b3c4d5e== \
  --file /home/ubuntu/migrate/test
```

To run the writing, simply execute the following command

```none
./migrate_influxdb.sh
```

#### Typical Problem

```none
Error: Failed to write data: unable to parse 'CREATE DATABASE xxx WITH NAME xxx': invalid field format.
```

#### Cause

The `backup_data` file may come with header, comments and other information, such as

```none
# INFLUXDB EXPORT: 1677-09-21T06:54:47+06:42 - 2262-04-12T06:47:16+07:00
# DDL
CREATE DATABASE xxx WITH NAME xxx
# DML
# CONTEXT-DATABASE:xxx
# CONTEXT-RETENTION-POLICY:xxx
# writing tsm data
...
{your measurement}
...
```

#### Solution

We are interested in lines below `# writing tsm data`. The easiest way is by removing the header from the file using `sed`

```none
sed -i '{start_line_number},{end_line_number}d' /path/to/your/backup/data
```

If the header contains 7 lines, and the file `backup_data` is located in `~/import`, the example of command is

```none
sed -i '1,7d' ~/import/backup_data
```

**_Explanation_**

`-i` flag means we want the action to be performed in-place, i.e. rewrite the original file.

`1,7` tells sed to target line 1 to 7

`d` means the action is `delete`

Confirm the header has been successfully removed

```none
head -n 10 ~/import/backup_data
```

**_Note_**

If database export is performed using `db_export.sh`, the issue is very unlikely to occur because the header cleanup is performed immediately after export.
