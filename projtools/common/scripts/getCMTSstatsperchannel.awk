#
# Awk script to get CMTS stats per channel
#

BEGIN { FS = " "; x = 0; }

{
    DirectionFlag=$1;
    CHANNEL=$2;

    Util= $3;
    TotalBytes=$4;
    TotalPkts=$5;
    TotalCollisions=$8;

    if (TotalPkts == 0) {
        collisionRate = 0.0;
    } else {
        collisionRate = TotalCollisions/TotalPkts;
    }

    TotalBW= $9;
    fieldType = $1;

    if (fieldType == 1) {
        printf("DS Channel: %d util:%3.3f, Total Bytes:%d, Total Pkts:%d,  BW Consumed(bps) %d \n",CHANNEL,Util,TotalBytes,TotalPkts, TotalBW);
    }

    if (fieldType == 0) {
        printf("US Channel: %d util:%3.3f, Total Bytes:%d, Total Pkts:%d,  BW Consumed %d, Collisions:%d, Collision Rate:%3.3f, BW Consumed(bps):%d \n",CHANNEL,Util,TotalBytes,TotalPkts,TotalBW, TotalCollisions, collisionRate, TotalBW);
    }

    x=x+1;
}

END { }

