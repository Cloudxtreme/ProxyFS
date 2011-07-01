
# ProxyFS

Creates a proxy filesystem using fuse for ruby to mount a mirror of a local directory.
Using the proxy mountpoint, changes to the files will be distributed to remote mirrors automatically and *live* using the SFTP protocol.
ProxyFS manages a log for each mirror, to re-sync a lost mirror when it is available again.

## State (Warning!)

This is an early alpha. Currently it's more like a proof of concept than usable. You better don't use it yet.
It will possibly delete all your files :-)

Currently, we use mysql for logging. Therefore, you'll have to install a mysql server or other database supported by active record and having transactions.

Please note, that you need space within the log directory, 
because each file is temporary written to the log directory and stored until it is replicated to each mirror.

## Run

Currently only Debian supported (within this README)

<pre>
  $ apt-get install fuse ruby irb libfusefs-ruby libnet-sftp2-ruby libactionmailer-ruby1.8 libactiverecord-ruby1.8 mysql-server libmysql-ruby
  $ modprobe fuse
</pre>

* Edit config/database.rb for mysql settings (logging).
* Edit config/mailer.rb for email notifications.
* To setup the database tables, run from the ProxyFS root directory as root (the database must already exist):

<pre>
  $ ruby database.rb
</pre>

Then, to mount ProxyFS, run as root:

<pre>
  $ ruby proxyfs.rb [local path] [mount point]
</pre>

To start the ProxyFS console, run as root:

<pre>
  $ irb -r console.rb
</pre>

Within the console, enter 'show_help' and press enter.
From the console, you can add mirrors.
To exit from the console, enter 'quit'.

## Use Cases

Say you have multiple webservers and directories with a large collection of rather static files.
You want both servers to have the same content within these directories.

Now, you have multiple options to replicate/synchronize these directories

- rsync, running once a hour, day, week, whatever

Unfortunately, rsync can't replicate/synchronize the files in a 'live' manner.

- drbd

Unfortunately, drbd will only work in a LAN using gigabit links (AFAIK).

- lsyncd or other inotify based replication/synchronization tools

Unfortunately, these tools can IMHO get out of sync easily or have to continously run rsync to stay in sync.
This behaviour is bad if you have to replicate/synchronize thousands of files and hundreds of gigabytes of data.

- **ProxyFS**

Will be more robust, because a write to the proxy mountpoint will automatically sync to all mirrors and a local directory live.
Is designed for WAN connections! Only the local write is synchronous, remote writes are asynchronous.
After a network outage, ProxyFS will use its log to replicate the not yet written operations to the mirrors again.
Therefore, mirrors can get down and will resync when they get available again.
ProxyFS assumes to be all mirrors in sync when it starts. Therfore, you'll have to initially use rsync one time, for example.


