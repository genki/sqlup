sqlup
    by James Moore
    http://sqlup.restphone.com

== DESCRIPTION:

sqlup is a set of libraries and utilities to automate backups of a MySQL server running on Amazon's EC2
service to Amazon's S3 storage service.  

=== Quick start

Create an S3 bucket named 'sqlup' for your backups.  (You'll need to choose a different name for your bucket.)

Install the gem:
  gem install sqlup

Put your S3 keys in a .sqluprc file in the backup user's home directory:
  cat ~/.sqluprc
  access_key_id: xxxxxxxxxxxxxxxx
  secret_access_key: xxxxxxxxxxxxxxxxx

Backup your database:
  sqlup binary -bucket sqlup
  
See what was written:
  sqlup ls -bucket sqlup
  
Start the backup daemon that will store the binary logs as they're written:
  sqlup_control start -- -logs_delay 10 log_daemon -bucket sqlup
  
Retrieve the backup files (where full:type_mysqldump:log_file_domU-12-31-35-00-35-42-bin.000019:log_position_0000000169 is the name of the full backup you want):
  sqlup get_logs -bucket sqlup -d /tmp
  sqlup get -bucket sqlup -d /tmp -name full:type_mysqldump:log_file_domU-12-31-35-00-35-42-bin.000019:log_position_0000000169

=== Usage

Get help:
  sqlup -h 
Back up the data files: 
  sqlup binary -bucket sqlup
Back up a mysqldump run: 
  sqlup mysqldump -bucket sqlup
Start the sqlup daemon to take a backup every 10 seconds, to the bucket 'sqlup', with a pidfile in /tmp:
  export SQLUP_PID_DIR=/tmp
  sqlup_control start -- -logs_delay 10 log_daemon -bucket sqlup
Get a list of the backup files:
  sqlup ls -bucket sqlup
Remove a backup file from the bucket 'sqlup':
  sqlup -bucket sqlup rm -name log:type_complete:log_file_fnord.000002
Remove obsolete current logs:
  obsolete_files=`bin/sqlup -bucket sqlup ls -backup_type log_current -skip_most_recent 3`
  for i in $obsolete_files ; do
  sqlup -bucket sqlup rm -name $i
  done
  
You need to specify your access codes using the AWS::S3 environment variables:

  export AMAZON_ACCESS_KEY_ID='xxxxxxx'
  export AMAZON_SECRET_ACCESS_KEY='xxxxxxxxxx'

  
It's primarily targeted at MySQL servers running on Amazon's EC2 virtual server system,
with backups sent to Amazon's S3 storage service.

=== What it backs up
There are three parts to a MySQL backup system:

1.	The actual MySQL data files (by default, the files in /var/lib/mysql).
2.	Full dumps using the mysqldump tool.
3.	The binary log files.

Normally, you'd make a full copy of your system using either #1 or #2, and then have sqlup make backups of the binary logs to S3 every N seconds.
Backups are tarred, gzip'ed, and split to fit into S3 buckets.

=== FAQs

*  Why would I want to make copies of the data files instead of using mysqldump?

Speed.  Recovering mysqldump files can take a while; recovering when you have copies of the data files is much faster.  If you've got a small database, though, just use mysqldump.  You can test this yourself; just do a mysqldump of your current database, and run it against a MySQL server on another machine.  If that's fast enough for you, you don't need to worry about the binary files.

* Can I use the database while it's being backed up?

Yes, sort of.  The binary backup is going to lock every table in the system until it's finished making a tarball of all the data files.  (A future enhancement will be to use a versioning file system.)  As long as no one writes to the database, reads will continue.  However, as soon as someone wants to write to a table, it's very likely that all future readers will be blocked until the backup is finished writing temporary files to disk.

* Is there an automated recovery system?

Not yet.  There's a command to get the backups back from S3, but you need to go through the standard mysql recovery process by hand once you have the files.


== FEATURES/PROBLEMS:

== TODO:

1.  Improve the recovery process.
2.  Improve the ability to do backups from slaves.

== REQUIREMENTS:

* You must run MySQL with binary logging enabled.  No logs == no backups.

== INSTALL:

  gem install sqlup
  
== LICENSE:

sqlup - a backup tool for MySQL, EC2, and S3

Copyright (C) 2007 James Moore

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
