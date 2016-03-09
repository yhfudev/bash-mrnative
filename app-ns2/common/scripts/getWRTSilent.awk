#
# Awk script to get Web response traffic bandwidth
#

BEGIN {
    FS = " "
    WRT = 0;
    sqWRT = 0;
    n = 0;
    lastValue = 0;
}

{
    fieldType = $1;
    {
        if (fieldType == 1) {
            lastValue = $2;
        }
    }
    {
        if (fieldType == 2) {
            if (lastValue > 0) {
                WRTsample = $2 - lastValue;
                if (WRTsample > 0) {
                    n=n+1;
                    WRT = WRT + WRTsample;
                    sqWRT = sqWRT + WRTsample * WRTsample;
                }
                lastValue = 0;
            }
        }
    }
}

END {
    if (n > 0) {
        print " " (WRT/n) " " (sqrt(sqWRT/n - (WRT/n)**2))
    } else {
        print "0.0 0.0"
    }
}

