# backupebl

perl backup script

Usage: ./make_backup.pl [options] <dir1> <dir2> <dir3> etc<br>
  <dir> - backup directory

Options:
  --backup-dir=<dir>         Set directory for backup files
  --file-prefix=<prefix>     File prefix
  --old-file-age=<days>      Old backups age in days
  --log-file=<path/log.file> Name log file
  --mail-from=<from-addr>    From address for mail
  --mail-to=<to-addr>        To address
  --mail-subj=<subject>      Letter subject
  --make-purge               Make perge old backups
