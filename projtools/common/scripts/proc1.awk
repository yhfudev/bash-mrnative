#
# Awk script to get stats for a CM
#

BEGIN { count=0; simTime=0; rawRatio=0.0; appRatio=0.0; UPBW=0.0 }

{
    count++;
    
    # printf(" CM id: %d  %d %d %d %d $\n",$1,$3,$5,$7,$9);

    if (count == 3) {
        simTime = $2;
        if ($3 > 0) {
            rawRatio = $5/$3;
        }
        if ($7 > 0) {
            appRatio = $9/$7;
        }
        if (simTime > 0) {
            UPBW = $3*8/simTime;
            APPBW = $7*8/simTime;
        }
    }
}

END {
    printf(" CM 3: raw DS:US byte ratio :%3.2f  application DS:US byte ratio: :%3.2f UPBW:%f APPUPBW:%f (sim time %d) \n",rawRatio,appRatio,UPBW,APPBW,simTime);
}

