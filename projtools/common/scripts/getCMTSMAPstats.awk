#
# Awk script to get CMTS MAP stats
#

# x: total number slots
# s: total number CS
# y: total number of data slots
# z: total pending requests
# a: total size in bytes  of MAP msgs
# MAPtime: total size in time of MAPs
# n: number of MAPs
# g: number of grants

BEGIN {
  FS = " ";
  x = 0; y = 0; z = 0; s = 0; a = 0; g = 0;
  nMAPS = 0; MAPtime = 0; InMAP=0; meanIEsPerMAP = 0;
  meanGrantsPendingPerMap = 0;
  IEsInThisMAP = 0;
  ACKtime = 0; ACKtimeMin = 10; ACKtimeMax = 0;
  numcont = 0; maxGrant=0; maxGrantTime=0;
} 

{
  fieldType = $1;
  if (fieldType == 0) {
    n=n+1;
    a=a+$6;
    MAPtime = MAPtime + ($4-$3);
    if (($3-$7) < ACKtimeMin) {
      ACKtimeMin = ($3-$7);
    }
    if (($3-$7) > ACKtimeMax) {
      ACKtimeMax = ($3-$7);
    }
    ACKtime = ACKtime + ($3 - $7);
    #the start of a new map
    if (IEsInThisMAP > 0) {
      nMAPS = nMAPS + 1;
      meanIEsPerMAP = meanIEsPerMAP + IEsInThisMAP;
      meanGrantsPendingPerMap =  meanGrantsPendingPerMap +($5-1-IEsInThisMAP);
      IEsInThisMAP = 0;
    }
  }
  if (fieldType == 1) {
    x=x+$9;
    if ($8 == 2) {
      s=s+$9;
      numcont=numcont + $9;
    }
    if ($8 == 0) {
      y=y+$9;
      g=g+1;
      if ($9 > maxGrant) {
        maxGrant = $9;
        maxGrantTime = $2;
      }
    }
    IEsInThisMAP = IEsInThisMAP + 1;
  }
}

END {
  print "CMTSMAP:total slots: " x;
  print "CMTSMAP:total CONTENTION slots: " s;
  print "CMTSMAP:total data slots: " y;
  print "CMTSMAP:percent contention slots: " ((s/x)*100)
  print "CMTSMAP:percent data slots: " ((y/x)*100)
  print "CMTSMAP:avg MAP size in bytes: " (a/n)
  print "CMTSMAP:avg MAP time in seconds: " (MAPtime/n)
  if (g == 0) { g = 1; }
  print "CMTSMAP:avg grant size " (y/g)
  print "CMTSMAP:total MAPS: " nMAPS;
  print "CMTSMAP:meanIEsPerMAP: " meanIEsPerMAP/nMAPS;
  print "CMTSMAP:meanNumberPENDINGGrantsPerMAP: " meanGrantsPendingPerMap/nMAPS;
  print "CMTSMAP:min ACK time: " ACKtimeMin;
  print "CMTSMAP:max ACK time: " ACKtimeMax;
  print "CMTSMAP:mean ACK time: " ACKtime/nMAPS;
  printf("CMTSMAP:max grant: %d,  at time:%f\n",maxGrant,maxGrantTime);
}
