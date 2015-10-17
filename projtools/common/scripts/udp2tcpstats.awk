#
# Awk script to convert UDP flow statistics to TCP-like flow statistics for post processing
#

BEGIN { A2=0; FS=" " }

{
	printf("%d %d %d %d %3.3f %d %d %3.6f %d %d %d %d\n", $1,$2,$3,$4,(100*$6),A2,A2,$9,$7,A2,A2,A2);
}

END { }

