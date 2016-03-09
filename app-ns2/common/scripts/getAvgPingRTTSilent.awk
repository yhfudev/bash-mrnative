#
# Awk script to calculate average ping RTT
#

BEGIN { FS = " " }
{ nl++; }
{ s=s+$2; }
END { print " " s/nl*1/1000 }

