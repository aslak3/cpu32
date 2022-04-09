#!/usr/bin/perl
#
# Convert a 16384 longword hex file to Altera Memory Image Format.
# See: https://www.mil.ufl.edu/4712/docs/mif_help.pdf
#
# STDIN->hex2mif.pl->STDOUT

my $offset = 0;

print "DEPTH = 16384;\n";
print "WIDTH = 32;\n";
print "ADDRESS_RADIX = DEC;\n";
print "DATA_RADIX = HEX;\n";
print "\n";
print "CONTENT\n";
print "BEGIN\n";

my $word;
while (sysread(STDIN, $longword, 8))
{
	next unless ($longword =~ /[0-9a-f]{8}/);
	printlongword($longword);
}
while ($offset < 16384)
{
	printlongword("00000000");
}
print "END;\n";

sub printlongword
{
	my ($word) = @_ ;
	if (($offset % 8) == 0) {
		print $offset . " : ";
	}
	print $word;
	if (($offset % 8) == 7) {
		print ";\n"; }
	else {
		print " ";
	}
	$offset++;
}
