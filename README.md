# backupebl

perl backup script

Usage: ./make_backup.pl [options] \<dir1\> \<dir2\> \<dir3\> etc<br>
  <dir> - backup directory <br>

Options:<br>
  --backup-dir=<dir>         Set directory for backup files<br>
  --file-prefix=<prefix>     File prefix<br>
  --old-file-age=<days>      Old backups age in days<br>
  --log-file=<path/log.file> Name log file<br>
  --mail-from=<from-addr>    From address for mail<br>
  --mail-to=<to-addr>        To address<br>
  --mail-subj=<subject>      Letter subject<br>
  --make-purge               Make perge old backups<br>
  <br>
