# Packrat

Packrat is an automated, modular backup system written in Bash. It has the
ability to do encrypted, incremental backups of your filesystem and can
store them somewhere offsite via FTP, SSH, or S3.

It can also backup MySQL and PostgreSQL databases, though these will not
be incremental backups, always a full dump.

Packrat has no ability to perform a restore process. You'll have to do
this yourself. See the **Filesystem Restores** section for a quick tutorial on how
to perform a restore with the `dar` utility.

**Before trusting a backup system, a conscientious operator should always
test it by performing a restore. Don't wait until you need it!**


## Installation

- Copy `packrat.conf` to `/etc/packrat.conf`
- Copy the `modules` directory `/usr/share/packrat/modules`
- Copy the `packrat` and `aws` scripts to somewhere in your PATH (eg:
  `/usr/bin`)
  - The `aws` script is only required if you're using the S3 upload
    module.
- Install the [dar](http://dar.linux.free.fr) utility. It's probably
  included your distro's package set somewhere.


## Setup

All global- and module-level configuration is done in `packrat.conf`.
Since this file will likely contain encryption keys or other sensitive
data, you should probably make it readable only by root (`chmod 600
/etc/packrat.conf`).

The configuration file is heavily-commented and should be reasonably
self-explanatory.


## Filesystem Backups

Though Packrat is modular, its main focus is backing up parts of your
filesystem. This functionality is contained in the `filesystem` module,
and it is the first section in the `packrat.conf` configuration file.

Packrat uses the [dar](http://dar.linux.free.fr) utility to perform
file-based backup and restore. It supports slicing, encryption, and
incremental backups, so it's well-suited to the task.

Provided the configuration variables are set correctly, Packrat should
handle the backups for you just fine.

But it doesn't do restores. That's your job.


## Filesystem Restores

Since `dar` is an incremental backup utility, you will need multiple
backup files to get back to your last backup point.

For example, let's say it's 2016-02-16, and you experience a catastrophic
loss of data. A hard drive gained sentience and decided that it couldn't
live without new episodes of Seinfeld, so it self-terminated. These things
happen.

You go into your backups directory to restore your `/home/sites`
directory, and you see these files:

    myserver-home-sites-20160211.1.dar
    myserver-home-sites-20160212.1.dar
    myserver-home-sites-20160213.1.dar
    myserver-home-sites-20160214.master.1.dar
    myserver-home-sites-20160214.master.2.dar
    myserver-home-sites-20160215.1.dar
    myserver-home-sites-20160216.1.dar

Good, we have backups right up to the current day. The files with a
`master` string in them are exactly that, masters -- these are full
backups, containing every file as it existed on that date. You'll note
that there are two master files for 2016-02-14. That's because we're using
slices in order to cap the maximum file size of any one backup file. The
`.2.dar` file continues the archive where the `.1.dar` file left off.

The other files, the ones with dates following the last master, are the
incrementals. These archives only store the files that have changed since
the last master was taken.

Because of this, we need the master files in order to restore. An
incremental file is not enough.

Let's also assume we used encryption on our backup files, and that we want
to restore the content of this archive to a different directory so we can
verify the contents before moving them into their original location.

To accomplish this, we'll have to restore _each_ file from the _most
recent_ master archive onwards, and _in the order_ they were taken. We'll
also omit the slice and extension from the filenames, as `dar` will attach
that part itself.

    # dar -x myserver-home-sites-20160214.master -R /restore_test -K costanza
    # dar -x myserver-home-sites-20160215 -R /restore_test -K costanza
    # dar -x myserver-home-sites-20160216 -R /restore_test -K costanza

At this point, we should should have our files fully restored in the
`/restore_test` directory. Huzzah!

For more nitty-gritty details, check out the [dar
tutorial](http://dar.linux.free.fr/doc/Tutorial.html).


## Creating New Modules

At present, Packrat only has a handful of included modules. If you need
some new functionality, then it's likely that you'll have to write your
own. You can use some of the modules in the `modules/` subdirectory for
your inspiration.

There are two types of modules: **backup** modules and **upload** modules.

### Backup Modules

A backup module understands how to backup a given resource (eg: a
filesystem, a database, a Redis store, etc).

Backup modules need to implement a single function called `mod_<name>`,
where `<name>` is the name of the module. The function does not receive any
arguments.

### Upload Modules

An upload module understands how to store this backup archive somewhere,
and how to remove old, outdated archives.

Upload modules need to implement three functions:

- `mod_<name>`: Uploads new archives to the remote. Accepts no arguments.
- `list_<name>`: Generates a list of files on the remote. Accepts no
  arguments.
- `purge_<name>`: Deletes a file from the remote. Accepts one argument,
  the filename to remove.


## Tips

- If using the same remote location (FTP, S3, whatever) for backing up
  multiple servers, you should use a different directory/bucket for each
  server. Otherwise some upload modules can get confused when they're
  counting file archives to determine how many old ones to remove.

