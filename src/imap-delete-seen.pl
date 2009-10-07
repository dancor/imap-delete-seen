#!/usr/bin/env perl

use strict;
use warnings;
use Net::IMAP::Simple::SSL;
use Config::General;

$| = 1;

my $conf = new Config::General('config');
my %config = $conf->getall;
print $config{'username'}."\n";

my $imap = Net::IMAP::Simple::SSL->new($config{'host'}) ||
   die "Unable to connect to IMAP: $Net::IMAP::Simple::errstr\n";
print "connected\n";

if (!$imap->login($config{'username'}, $config{'password'})) {
    print STDERR "Login failed: " . $imap->errstr . "\n";
    exit(64);
}

my @folders = $imap->mailboxes();
my $deleted = 0;
foreach my $folder (@folders) {
    print $folder, "\n";
    if ($folder eq 'Deleted Items') {
        next;
    }
    my $num_messages = $imap->select($folder);
    if (!$num_messages) {
        next;
    }

    print "$num_messages\n";
    my $offset = 0;
    for (my $i = 1; $i <= $num_messages; $i++) {
        my @flags = $imap->msg_flags($i - $offset);
        if (grep {$_ eq '\\Seen'} @flags) {
            $imap->delete($i - $offset);
            print ".";
            $deleted++;
            if ($deleted >= 100) {
                print $imap->expunge_mailbox($folder), "\n";
                $offset += 100;
                $deleted = 0;
            }
        }
    }
    print $imap->expunge_mailbox($folder), "\n";
}

