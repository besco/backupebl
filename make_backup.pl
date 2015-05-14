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
$quiet=0;


#Get date and time for logfile. like that "15/04/2015 21:28:24" and for backup file, like that 15/04/2015_21:28:24
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

sub toLog {
    my $message = $_[0];
    my $fpara = $_[1];

    $logString = &fTimeStamp(logfile)."$message\n";
    if ($quiet eq 0) {
	print $message."\n";
    };
    $log->print($logstring);
    if ($fpara =~ /1/) {
	return $message."\n";;
    };
};

#Sending email
sub sendMail {
    $message = $_[0];
    $buffer .= &toLog(" * Sending report backup script",1);
    open(MAIL, "|/usr/sbin/sendmail -t");
    print MAIL "To: ".$conf{mail_to}."\n";
    print MAIL "From: ".$conf{mail_from}."\n";
    print MAIL "Subject: ".$conf{mail_subject}."\n\n";

    print MAIL $message;

    close(MAIL);
    $buffer .= &toLog(" - Sending email successfully");
    
};

#make backup
sub makeBackup {
    #get dirs from command line
    my @arc_dir=@_;
    $countdir=$#arc_dir+1;
    $buffer .= &toLog(" - Checking ".$countdir." directories:",1);
    for ($i=0;$i<=$#arc_dir;$i++) {
	$buffer .= &toLog(" -- Checking $arc_dir[$i] ",1);
	if (!-d $arc_dir[$i]) {
	    $buffer .= &toLog(" !! Directory $arc_dir[$i] does not exist. Skiping. ",1);
	    #splice @array, $i, 1;	    
	} elsif (-d $arc_dir[$i]) {
	    $buffer .= &toLog(" - OK",1);
	    $dir_string .=" ".$arc_dir[$i];
	};
    };
    if ($dir_string) {
	$countdir=$#arc_dir+1;
	$buffer .= &toLog(" - Archiving ".$countdir." directories.",1);
        $output=`tar -zvcf $conf{backup_dir}/$conf{file_name}.tar.gz $dir_string 2>&1`;
        $quiet=1;
        $buffer .= &toLog(" - ".$output,1);
        $quiet=0;
    } else {
	$buffer .= &toLog(" - Archiving aborted. Nothing to archive.",1);
    };
};

#Purge old backup files. Age set from command line in days.
sub purgeOld {
    $buffer .= &toLog(" * Start purging old archives",1);
    $path = $_[0];
    my @files;
    my @newest_files;
    if (-d $path) {
	# Open dir with backup (set in header)
	opendir my $dir, $path or die $!;
	# read files in array
	@all_files = readdir $dir;
	closedir $dir;
	if ($#all_files gt 0) {
	    # Get backup files newer than the specified option --old-file-age
	    push(@newest_files, split(/ /,`find $path -type f -name "$conf{file_prefix}*.tar.gz" -atime -$conf{old_files_age} | xargs`));
	    # Get old backup files for del
	    push(@files, split(/ /,`find $path -type f -name "$conf{file_prefix}*.tar.gz" -atime +$conf{old_files_age} | xargs`));
	    $buffer .= &toLog(" - Found ".($#files+1)." old file(s).",1);
	    for ($i=0;$i<=$#files;$i++) {
		chomp($files[$i]);
	        $buffer .= &toLog(" - Deleting old backup $files[$i]",1);
	        unlink($files[$i]);
	        if (!$!) {
	    	    $buffer .= &toLog(" - Deleting $files[$i] successful",1);
		} else {
		    $buffer .= &toLog(" - Error deleting old backup $files[$i] errno: $!",1);
		};
	    };
	    $buffer .= &toLog(" - Found ".($#newest_files+1)." files newer than the specified option --old-file-age ($conf{old_files_age} days). Files will not be deleted:",1);
	    $stringlog="";
	    # Get age of new backup files 
	    for ($i=0;$i<=$#newest_files;$i++) {
		chomp($newest_files[$i]);
		my $mtime = (stat "$newest_files[$i]")[9];
		my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($mtime);
		$year+=1900;
		$mon+=1;
		$buffer .= &toLog(" -- $newest_files[$i] (Create date: $mon/$mday/$year)",1);
	    };
	} elsif ($#all_files le 0) {
	    $buffer .= &toLog(" - Found 0 files. Maybe new directory?",1);
	};
    } elsif (!-d $path) {
	$buffer .= &toLog(" - $path does not exist.",1);
    };
    $buffer .= &toLog(" - Purging finished.",1);
};

# get commandline options
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

# print help
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
    $buffer .= &toLog(" * Starting backup script",1);
    if (@dir_for_arc) {
	&makeBackup(@dir_for_arc);
    };

    if ($purge) {
	&purgeOld($conf{backup_dir});
    };
    $buffer .= &toLog(" * Finish backup script",1);
    &sendMail($buffer);
};
