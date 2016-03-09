#
# Awk script to get CMTS stats
#

BEGIN {
    FS = " " 
    TestTime = 0.0; TotalBytesSent = 0.0; TotalAppBytesSent = 0.0; TotalBytesReceived = 0.0;
    TotalFramesReceived = 0.0; TotalPDUsReceived = 0.0; TotalFramesSent = 0.0; TotalAppBytesReceived = 0.0;
    UpstreamBW = 0.0; DownstreamBW = 0.0;
}

#We account for 4.7% overhead in DS direction, 8% OH in US
{
    TestTime = $1;
    TotalBytesSent = $2;
    TotalAppBytesSent = $7;
    TotalBytesReceived = $4;
    TotalFramesSent = $3;
    TotalFramesReceived = $5;
    TotalPDUsReceived = $6;
    TotalAppBytesReceived = $9;

    if ($TotalFramesReceived < 1) {
        $TotalFramesReceived = 1;
    }
}

END {
    UpstreamBW = TotalBytesReceived*8/TestTime;
    DownstreamBW = TotalBytesSent*8/TestTime;

    printf("TotalFramesReceived %d;  TotalFramesSent: %d (#PDUs US:%d,#plaindataUS:%d, #MgtUS:%d) \n",
           TotalFramesReceived,TotalFramesSent,TotalPDUsReceived,$23,$18);
    printf("UpstreamBW Consumed:%d;  DownstreamBW Consumed:%d \n", UpstreamBW,DownstreamBW); 

    print "Percent of all US best effort GRANTS produced by: " ;
    #total_num_BE_pkts - total_num_piggy_reqs / total_num_BE_pkts

    if (TotalPDUsReceived > 0) {
        print "  via  contention (including concat requests): " (($16*1.0/TotalPDUsReceived)*100); 

        #total_num_concatdata_pkts / total_num_BE_pkts
        print "  via just concatonated contention requests:  "(($20/TotalPDUsReceived)*100);
        #total_num_piggy_reqs / total_num_BE_pkts
        print "  via piggybacking:  " (($15/TotalPDUsReceived)*100);
    } else {
        print "  via  contention (including concat requests):0  Via just concatonated contention requests: 0,  via piggybacking:  0";
    }

    if (TotalFramesReceived == 0) {
        TotalFramesReceived = 1;
    }

    print "Percent of all US ARRIVALS were:  " ;
    print "Percent of all frames that are management (all contention requests+rngs) " (($18/TotalFramesReceived)*100)
    print "Percent of all frames that contain CONTENTION REQUEST message " (($22/TotalFramesReceived)*100)
    print "Percent of all frames that contain data 1: " (((TotalFramesReceived-$18)/TotalFramesReceived)*100)
    print "Percent of all frames that contain data 2: " (($23/TotalFramesReceived)*100)
    print "Percent of all frames that were in concatentated frames " (($24/TotalFramesReceived)*100)
    print "Percent of all frames that contain USER data " (($25/TotalFramesReceived)*100)
    print "Percent of all frames (including mgt) that were fragmented " ((($21)/TotalFramesReceived)*100)

}


