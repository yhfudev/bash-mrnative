#
# Awk script to get CM MAP stats
#

BEGIN { FS = " "; x = 0; s = 0; }

{
    fieldType = $1;
    if (fieldType == 0) {
    	{x=x+$7} 
    }
    if (fieldType == 3) {
  	if ($6 == 2) {
  	    s=s+$7;
  	}
    }
}

END {
    print "total slots: " x;
    print "total CONTENTION slots: " s;
    print "percent contention slots: " (s/x*100)
}

