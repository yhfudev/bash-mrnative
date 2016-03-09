#
# Awk script to get CM stats
#

BEGIN {
    FS = " " 
    x=0; upPackets=0; up=0; down=0; downPackets=0; 
    lossRate = 0.0
    totalUSQueueDrops=0;
    numcont= 0.0; numcoll=0.0;
    avgCMCR=0.0; piggys=0.0; tdelay=0.0; rdelay=0.0;
    numberFrames=0; numberMgmtFrames=0; numberStatusFrames=0; numberFrags=0;
    avgfCont = 0.0; avgBackoff = 0.0;
    highestUSBWCM_ID=0; highestUSBW=0.0; highestDSBWCM_ID=0; highestDSBW=0.0;
}

{
    x++; 

    upPackets=upPackets+$4;
    up=up+$3; 
    down=down+$5;
    downPackets=downPackets+$6;

    totalUSQueueDrops=totalUSQueueDrops+$11;
    lossRate=lossRate+$12;
    numcoll=numcoll+$13;
    avgCMCR = avgCMCR+$14
    piggyReqs=piggyReqs+$19;
    numcontReqs=numcontReqs + $20;
    numcontReqsDenied=numcontReqsDenied + $21;
    avgfCont =avgfCont+ $23;
    avgBackoff =avgBackoff+ $24;

    tdelay=tdelay+$25;
    qdelay=qdelay+$26;
    rdelay=rdelay+$27;
    Nrdelay=Nrdelay+$28;

    numberFrames=numberFrames+$33;
    numberMgtFrames=numberMgtFrames+$34;
    numberStatusFrames=numberStatusFrames+$35;
    numberFrags=numberFrags+$36;

    if ($17 > highestUSBW) {
        highestUSBW=$17;
        highestUSBWCM_ID=$1;
    }
    if ($18 > highestDSBW) {
        highestDSBW=$18;
        highestDSBWCM_ID=$1;
    }

}

END {
    printf("NumberCMs:%d,   total packets sent:%16.0f,  total packets received:%16.0f\n", $1, upPackets, downPackets);
    printf(" Number Sent  Frames:%d,  Number Mgt Frames:%d, Number Status Frames:%d \n", numberFrames,numberMgtFrames,numberStatusFrames);
    printf("US: largest BW consumed by cm_id::%d (%12.0f) \n ", highestUSBWCM_ID, highestUSBW);
    printf("DS: largest BW consumed by cm_id:%d (%12.0f)\n", highestDSBWCM_ID, highestDSBW);
    printf("Avg total access delay: %3.6f, Avg request access delay: %3.6f, Avg queue delay: %3.6f, Avg NORMALIZED request access delay: %3.6f \n ", tdelay/x,rdelay/x,qdelay/x,Nrdelay/x);

    printf("Number of collisions: %d, Aggregate Collision Rate(CR1): %3.3f,  Avg CM CR(CR2):%3.3f\n ", numcoll, (100*numcoll)/numcontReqs,  avgCMCR/x);

    printf("Average first collision backoff: %3.6f,  Average backoff: %3.6f \n ",  avgfCont/x,avgBackoff/x);

    printf("total lossRate:%d, total lossCount:%d total x:%d \n",lossRate,lossCount,x);
    if (numcontReqs > 0) {
         printf(" Number of US losses:%d, Aggregate US loss rate:%3.3f, Avg CM US loss rate: %3.3f,  Number Contention Requests denied:%d, Percentage Denials:%3.3f  \n", lossCount,lossCount/numberFrames,	 lossRate/x,numcontReqsDenied,100*numcontReqsDenied/numcontReqs);
    } else {
         printf(" Number of US losses:%d, Aggregate US loss rate:%3.3f, Avg CM US loss rate: %3.3f,  Number Contention Requests denied:%d, Percentage Denials:0  \n", lossCount,lossCount/numberFrames,	 lossRate/x,numcontReqsDenied);
}

    printf("Ratio of:   number contention requests  to total number Frames: %3.3f,  piggys/totalPkts: %3.3f, Fragments/numberFrames: %3.3f \n", numcontReqs/numberFrames, piggys/numberFrames, numberFrags/numberFrames );
}

