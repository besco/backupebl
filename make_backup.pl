#!/usr/bin/perl
# backup script by Wasiliy Besedin. besco@yabesco.ru, 2:5028/68@fidonet.org, skype: unique-login-for-all

use Time::Local;
use FileHandle;

# Defaults
# Directory for backups files
$conf{backup_dir}='/usr/home/besco/work/backups/';
# Prefix for filename
$conf{file_prefix}='pre_';
# Timestamp for filename
$conf{file_timestamp}=&fTimeStamp(stamp);
# File name
$conf{file_name}=$conf{file_prefix}."".$conf{file_timestamp};
# Log file
$conf{file_log}="/var/log/mybackup.log";
# From address for email 
$conf{mail_from}='hp@yabesco.ru';
# TO address for email
$conf{mail_to}='besco@yabesco.ru';
# Subject for email
$conf{mail_subject}='Backup at '.&fTimeStamp(logfile);
# Age old backups in days
$conf{old_files_age}=30;

sub fTimeStamp {
 $param = $_[0];
 ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime(time);
 $year+=1900;
 $mon=substr($mon+101,1);
 $mday=substr($mday+100,1);
 $hour=substr($hour+100,1);
 $min=substr($min+100,1);
 $sec=substr($sec+100,1);
 if ($param eq "stamp") {
    return $mday."-".$mon."-".$year."_".$hour.":".$min.":".$sec;
 } elsif ($param eq "logfile") {
    return $mday."/".$mon."/".$year." ".$hour.":".$min.":".$sec;
 } else {
    return &fTimeStamp(stamp);
 };
}

sub sendMail {
    $message = $_[0];
    $buffer .= &fTimeStamp(logfile)." * Sending report backup script\n";
    open(MAIL, "|/usr/sbin/sendmail -t");
    print MAIL "To: ".$conf{mail_to}."\n";
    print MAIL "From: ".$conf{mail_from}."\n";
    print MAIL "Subject: ".$conf{mail_subject}."\n\n";

    print MAIL $message;

    close(MAIL);
    print "Email Sent Successfully\n";
    $log->print(&fTimeStamp(logfile)." - Sending email successfully\n");
    
};

sub makeBackup {
    my @arc_dir=@_;
    $countdir=$#arc_dir+1;
    $stringlog=&fTimeStamp(logfile)." - Checking ".$countdir." directories:\n";
    $log->print($stringlog);
    $buffer .= $stringlog;
    for ($i=0;$i<=$#arc_dir;$i++) {
	$string=&fTimeStamp(logfile)." -- Checking $arc_dir[$i] ";
	$log->print($string);
	$buffer.=$string;	
	if (!-d $arc_dir[$i]) {
	    $stringlog="\n".&fTimeStamp(logfile)." !! Directory $arc_dir[$i] does not exist. Skiping. \n";
	    $log->print($stringlog);
	    $buffer .= $stringlog;
	    #splice @array, $i, 1;	    
	} elsif (-d $arc_dir[$i]) {
	    $stringlog=" - OK\n";
	    $log->print($stringlog);
	    $buffer .= $stringlog;
	    $dir_string .=" ".$arc_dir[$i];
	};
    };
    if ($dir_string) {
	$countdir=$#arc_dir+1;
	$stringlog=&fTimeStamp(logfile)." - Archiving ".$countdir." directories.\n";
	$stringlog .= $sdir_string;
	$log->print($stringlog);
	$buffer .= $stringlog;
        $output=`tar -zvcf $conf{backup_dir}/$conf{file_name}.tar.gz $dir_string 2>&1`; 
        $buffer .= &fTimeStamp(logfile)." - ".$output;
    } else {
	$stringlog=&fTimeStamp(logfile)." - Archiving aborted. Nothing to archive.\n";
	$log->print($stringlog);
	$buffer .= $stringlog;
    };
};

sub purgeOld {
    $log->print(&fTimeStamp(logfile)." - Start purging old archives\n");
    $buffer .= &fTimeStamp(logfile)." * Start purging old archives\n";
    $path = $_[0];
    my @files;
    my @newest_files;
    if (-d $path) {
	opendir my $dir, $path or die $!;
	@all_files = readdir $dir;
	closedir $dir;
	if ($#all_files gt 0) {
	    push(@newest_files, split(/ /,`find $path -type f -name "*" -atime -$conf{old_files_age} | xargs`));
	    push(@files, split(/ /,`find $path -type f -name "*" -atime +$conf{old_files_age} | xargs`));
	    $stringlog  = &fTimeStamp(logfile)." - Found ".($#files+1)." old file(s).\n";
    	    $log->print($stringlog);
    	    $buffer .= $stringlog;
	    for ($i=0;$i<=$#files;$i++) {
		chomp($files[$i]);
	        $stringlog=&fTimeStamp(logfile)." - Deleting old backup $files[$i]\n";
	        $log->print($stringlog);
	        $buffer .= $stringlog;
	        unlink($files[$i]);
	        if (!$!) {
	    	    $stringlog=&fTimeStamp(logfile)." - Deleting $files[$i] successful\n";
		    $log->print($stringlog);
		    $buffer .= $stringlog;
		} else {
		    $stringlog=&fTimeStamp(logfile)." - Error deleting old backup $files[$i] errno: $!\n";
		    $log->print($stringlog);
		    $buffer .= $stringlog;
		};
	    };
	    $stringlog  = &fTimeStamp(logfile)." - Found ".($#newest_files+1)." files newer than the specified option --old-file-age ($conf{old_files_age} days). Files will not be deleted:\n";
	    $log->print($stringlog);
	    $buffer .= $stringlog;
	    $stringlog="";
	    for ($i=0;$i<=$#newest_files;$i++) {
		chomp($newest_files[$i]);
		my $mtime = (stat "$newest_files[$i]")[9];
		my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($mtime);
		$year+=1900;
		$mon+=1;
		$stringlog .= &fTimeStamp(logfile)." -- $newest_files[$i] (Create date: $mon/$mday/$year)\n";
	    };
	    $log->print($stringlog);
	    $buffer .= $stringlog;
	} elsif ($#all_files le 0) {
	    $stringlog=&fTimeStamp(logfile)." - Found 0 files. Maybe new directory?\n";
	    $log->print($stringlog);
	    $buffer .= $stringlog;
	};
    } elsif (!-d $path) {
	$stringlog=&fTimeStamp(logfile)." - $path does not exist.\n";
	$log->print($stringlog);
	$buffer .= $stringlog;
    };
    $stringlog=&fTimeStamp(logfile)." - Purging finished.\n";
    $log->print($stringlog);
    $buffer .= $stringlog;
};

for ($i=0;$i<=$#ARGV;$i++) {
    if (substr($ARGV[$i],0,2) eq "--") {
	if ($ARGV[$i] == "--make-purge") { $ARGV[$i] .= "=1"; };
	@cmd_str=split(/=/,$ARGV[$i]);
	if (!$cmd_str[1]) { 
	    print "Error in ".$ARGV[$i]." Stoping.\n";
	    exit;
	} elsif ($cmd_str[0] eq "--backup-dir") { 
	    $conf{backup_dir}=$cmd_str[1];
	} elsif ($cmd_str[0] eq "--log-file") {
	    $conf{file_log} = $cmd_str[1];
	} elsif ($cmd_str[0] eq "--file-prefix") { 
	    $conf{file_prefix}=$cmd_str[1];
	    $conf{file_name}=$conf{file_prefix}."".$conf{file_timestamp};  
	} elsif ($cmd_str[0] eq "--old-file-age") { 
	    $conf{old_file_age}=$cmd_str[1]; 
	} elsif ($cmd_str[0] eq "--mail-from") { 
	    $conf{mail_from}=$cmd_str[1]; 
	} elsif ($cmd_str[0] eq "--mail-to") { 
	    $conf{mail_to}=$cmd_str[1]; 
	} elsif ($cmd_str[0] eq "--mail-subj") { 
	    $conf{mail_subj}=$cmd_str[1]; 
	} elsif ($cmd_str[0] eq "--make-purge") {
	    $purge="1"; 
    	} else { print "- Unknown options $ARGV[$i]\n"; };
    } else {
	push(@dir_for_arc,$ARGV[$i]);
    };
};

if (!@dir_for_arc && !$purge) {
    print $purge;
    print "\n";
    print "Usage: $0 [options] <dir1> <dir2> <dir3> etc\n";
    print "  <dir> - backup directory\n";
    print "\n";
    print "Options: \n";
    print "  --backup-dir=<dir>         Set directory for backup files\n";
    print "  --file-prefix=<prefix>     File prefix \n";
    print "  --old-file-age=<days>      Old backups age in days \n";
    print "  --log-file=<path/log.file> Name log file \n";
    print "  --mail-from=<from-addr>    From address for mail \n";
    print "  --mail-to=<to-addr>        To address \n";
    print "  --mail-subj=<subject>      Letter subject \n";
    print "  --make-purge               Make perge old backups \n";
    print "\n";
    exit;

} else {
    $log = FileHandle->new($conf{file_log}, "a+") || die "Failed to open log file ".$conf{file_log}."\n";
    $logstring = " * Starting backup script\n";
    $log->print(&fTimeStamp(logfile)."".$logstring);
    $buffer .= &fTimeStamp(logfile)."".$logstring;
    if (@dir_for_arc) {
	&makeBackup(@dir_for_arc);
    };

    if ($purge) {
	&purgeOld($conf{backup_dir});
    };
    $stringlog=&fTimeStamp(logfile)." * Finish backup script\n";
    $log->print($stringlog);
    $buffer .= $stringlog;
    &sendMail($buffer);
};
