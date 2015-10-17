#
# Awk script to get Web traffic bandwidth
#

BEGIN {
    {A1=8888;A2=0;FS = " "}
}

{
    {nl++} {curTime=$2} {s=s+$5} 
}

END {
    DS1= s*1460;
    printf("%d %d %d %d %d %d %d %d %12d %d %d %d\n",  A1,DS1,A2,A2,A2,A2,A2,A2,s*1460.0*8.0/curTime,A2,A2,A2);
}

