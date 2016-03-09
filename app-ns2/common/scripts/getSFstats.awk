#
# Awk script to get SF stats
#

	# param1:BGID of interest
	# param2:BGID range start 
	# param3:BGID range stop

BEGIN {
    FS = " "
    BGID = Param1; BGIDstart = Param2; BGIDstop = Param3;
    sampleCount = 0; arrivalRate = 0; serviceRate = 0; aggregateServiceRate = 0;
    lossRate = 0.0; queueDelay = 0.0; partialBytes = 0; totalBytes = 0; numberFlows = 0;
}

{
    totalBytes = totalBytes + $4;
    lineBGID = $2;
    lineSFID = $1;

    if (BGID == 0) {
        arrivalRate = arrivalRate + $7;
        serviceRate = serviceRate + $6;
        aggregateServiceRate = aggregateServiceRate + $6;
        lossRate = lossRate + $8;
        queueDelay = queueDelay + $9;
        numberFlows = numberFlows + 1;
    } else {
        if ((BGIDstart > 0) && (BGIDstop > 0 )) {
        } else {
            if (BGID == $2) {
                if (lineSFID > 3) {
                    partialBytes = partialBytes + $4;
                    arrivalRate = arrivalRate + $7;
                    serviceRate = serviceRate + $6;
                    aggregateServiceRate = aggregateServiceRate + $6;
                    lossRate = lossRate + $8;
                    queueDelay = queueDelay + $9;
                    numberFlows = numberFlows + 1;
                }
            }
        }
    }
}

END {
    if (numberFlows > 0) {
        arrivalRateM = arrivalRate/numberFlows;
        serviceRateM = serviceRate/numberFlows;
        lossRateM = lossRate/numberFlows;
        queueDelayM = queueDelay/numberFlows;
    }

    if (totalBytes > 0) {
        BWpercentage = 100 * partialBytes / totalBytes;
    } else {
        BWpercentage = 0.0;
    }

    if (BGID == 0) {
        printf("BGID #Flows      ArrivalRate       ServiceRate         LossRate  pktDelay         totalBytes BWpercentage  aggServiceRate\n");
        printf(" %d   %d\t\t%10.0f\t%10.0f\t\t%2.2f\t%3.6f\t%12d\t100.0\t%10.0f\n", BGID, numberFlows,arrivalRateM,serviceRateM,lossRateM,queueDelayM,totalBytes, aggregateServiceRate);
    } else {
        printf(" %d   %d\t\t%10.0f\t%10.0f\t\t%2.2f\t%3.6f\t%12d\t%3.1f\t%10.0f\n", BGID, numberFlows,arrivalRateM,serviceRateM,lossRateM,queueDelayM,partialBytes,BWpercentage,aggregateServiceRate);
    }
}
