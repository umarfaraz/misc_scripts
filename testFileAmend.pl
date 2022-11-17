#!/usr/bin/env perl
use strict;
use warnings;
   
# FileChange.pl
my $filename = shift;       # Get the filename from command line.

print "Enter your pass: ";
my $cmd_pass=<STDIN>;
chomp($cmd_pass);

# Create a filehandle called FILE and connect to the file.
open(FILE, $filename) or die "Can't open $filename: $!";
# Read the entire file into an array in memory.
my @lines = <FILE>;
close(FILE);
my @temp = grep(/^websso_pass/, @lines);
my $pass_line = join ( '', @temp );
print "Pass Line:: $pass_line\n";
my ($tmp1, $file_pass ) = split('=', $pass_line);
$file_pass =~ s/^\s+|\s+$//;
if ( $file_pass eq $cmd_pass ) {
	print "Password Matches File Pass !!!";
} else {
	print "Ahh ...its a mismatch...Updating Now";
	updateFile($cmd_pass);
}

sub updateFile{
	my $f_pass = shift;
	open(FILE, ">$filename") or die "Can't write to $filename: $!";
	foreach my $line (@lines) {
		if ( $line =~ /websso_pass/ ) {
			my ($key, $value ) = split ('=' , $line);
			$key =~ s/^\s+|\s+$//;
			$f_pass =~ s/^\s+|\s+$//;
			print FILE "$key"."=".$f_pass."\n";
		} else {
			print FILE $line;
		}
	}
	close(FILE);
}
