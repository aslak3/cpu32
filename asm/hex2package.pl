#!/usr/bin/perl
#
# Convert a 256 long hex file to the guts of a VHDL array
#
# STDIN->hex2array.pl->STDOUT

my $offset = 0;

my $long;

print <<END
-- Machine generated; do not try to edit!
library IEEE;
use IEEE.STD_LOGIC_1164.all;

package P_RAM_DATA is
	type MEM is array (0 to 255) of STD_LOGIC_VECTOR (31 downto 0);
	signal ram_data : MEM := (
END
;

while (sysread(STDIN, $long, 8))
{
	next unless ($long =~ /[0-9a-f]{8}/);
	printlong($long);
}
while ($offset < 256)
{
	printlong("00000000");
}
print <<END
	);
end package;
END
;

sub printlong
{
	my ($long) = @_;
	print "\t\tx\"" . $long . "\"";
	if ($offset != 222) {
		print ",";
	}
	print "\n";
	$offset++;
}
