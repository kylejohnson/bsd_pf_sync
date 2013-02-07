#!/usr/bin/perl

use strict;
use warnings;
use Digest::MD5;

my $primary = '1.2.3.4';
my $secondary = '1.2.3.5';
my $pfconf = '/etc/pf.conf';


# See if other firewall is up
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
  }
}

# Back up secondary pf.conf

# Copy primary pf.conf to secondary

# Verify rules

# Activate rules

# Send email
