
# Proxyfs

Creates a proxy filesystem using fuse for ruby to mount a mirror of a local directory.
Using the proxy mountpoint, changes to the files will be distributed to remote mirrors automatically and *live*.
A transaction mechanism will provide good synchronicity, even if network problems will occur.

## State (Warning!)

This is an early alpha. Currently it's more like a proof of concept than usable. You better don't use it yet.
It will possibly delete all your files :-)

## Run

Currently only Debian supported (within this README)

$ apt-get install fuse ruby libfusefs-ruby liblog4r-ruby libnet-sftp2-ruby

$ modprobe fuse

Edit the config file

$ ruby main.rb config.yml

## Use Cases

Say you have two multiple webservers and directories with a large collection of rather static files.
You want both servers to have the same content within these directories.

Now, you have multiple options to replicate/synchronize these directories

- rsync, running once a hour, day, week, whatever

Unfortunately, rsync can't replicate/synchronize the files in a 'live' manner.

- drbd

Unfortunately, drbd will only work in a LAN using gigabit links (AFAIK).

- lsyncd or other inode based replication/synchronization tools

Unfortunately, these tools can IMHO get out of sync easily.

- **Proxyfs**

Will be more robust, because a write to the proxy mountpoint will automatically sync to all mirrors and a local directory live.
The write will go to all mirrors or none. Can be used with WAN connections! As the writes are synchronously written, the performance 
will differ for different connections.

