#
# Awk script to get CM concatenation stats
#


BEGIN { FS = " "; nl = 0; s=0; up=0; down=0; lossRate=0; numcont=0; numcoll=0; piggys=0; delay=0; numberpktsFrame=0; }
{
	if ($24 > 0) {
		{nl++}
		{s=s+$7}
		{up=up+$2}
		{down=down+$1}
		{lossRate=lossRate+$5}
		{numcont=numcont + $15}
		{numcoll=numcoll+$6}
		{piggys=piggys+$14}
		{delay=delay+$18}
		{numberpktsFrame=numberpktsFrame+$24}
	}
}
END {
	if (nl > 0.0) {
		print "average # pkts/frame: " numberpktsFrame/nl
	} else {
		print "average # pkts/frame: no data"
	}
}

