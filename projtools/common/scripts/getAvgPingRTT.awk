#
# Awk script to calculate average ping RTT
#

BEGIN { FS = " "; }
{ nl++; }
{ s=s+$2; }
END { print "average ping RTT (ms): " s/nl }

