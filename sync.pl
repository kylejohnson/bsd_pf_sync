#!/usr/bin/perl

use strict;
use warnings;
use Digest::MD5;

my $primary = '1.2.3.4';
my $secondary = '1.2.3.5';
my $pfconf = '/etc/pf.conf';
my $backupdir = '/root';
my $time = `date +"%Y%m%d%H%M`;
my $email_diff = 0; # Change to 1 to enable emailing of diff
my $email_address = 'user@domain.tld'; # Change this to the user which should receive the diff


# See if other firewall is up
# Add support for other ways of checking up (e.g., ssh, telnet, nmap)
sub check_up {
  my $exit = system("ping -c1 $secondary 2>&1 > /dev/null");
  if ($exit) {
    check_commit()
  }
}

# Check for uncommitted changes
sub check_commit {
 my $exit = system("cd /etc/ && git diff --quiet pf.conf");
 if ($exit) {
   check_rule_state()
 }
}

# Check to see if rules already match
sub check_rule_state {
  open (my $fh, $pfconf);
  binmode($fh);
  my $primary_md5 = Digest::MD5->new->addfile(*$fh)->hexdigest;
  close ($fh);

  my $secondary_md5 = `ssh root\@$secondary md5 -q /etc/pf.conf`;

  if ($primary_md5 ne $secondary_md5) {
    backup_pf();
  } else {
    die "pf.conf on $primary and $secondary already match";
  }
}

# Back up secondary pf.conf
sub backup_pf {
  print_message('Backing up secondary pf.conf');
  `ssh root\@$secondary cp /etc/pf.conf $backupdir/pf.conf.$time` or die "Could not backup pf.conf on $secondary: $!";
  send_rules();
}

# Copy primary pf.conf to secondary
sub send_rules {
  print_message("Sending pf.conf to $secondary");
  `scp -q /etc/pf.conf root\@$secondary:/etc/pf.conf` or die "Could not send pf.conf to $secondary: $!";
  verify_rules();
}

# Verify rules
sub verify_rules {
  `ssh root\@$secondary pfctl -q -n -f /etc/pf.conf` or die "pf.conf failed to parse correctly on $secondary: $!";
  activate_rules();
}

# Activate rules
sub activate_rules {
  `ssh root\@$secondary pfctl -q -f /etc/pf.conf` or die "pf.conf failed to activate on $secondary: $!";
}

# Send email
sub send_email {
  if ($email_diff) {
    my $subject = `git log -1 --oneline`;
    `git diff HEAD^..HEAD /etc/pf.conf|mail -s "BSD Firewall Change - $subject" $email_address`;
  }
}

sub print_message {
  my $message = $_;
}
