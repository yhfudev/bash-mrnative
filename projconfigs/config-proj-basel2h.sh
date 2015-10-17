#!/bin/sh
# config file for the simulations

# the test information to be showed
MSG_TITLE="Case Base: Competing flows in DOCSIS 3.1"
MSG_DESCRIPTION="Test various competing flows react to the changing profiles, it'll test UDP,TCP,HAS,and mix HAS with UDP/TCP flows."
PREFIX="basel2h"

# the message log file
#FN_LOG="log.txt"
FN_LOG="/dev/null"

# the stop time for the test
TIME_STOP=160.2

# the start time for measure the throughput
TIME_START=5

# the maximum bitrate of the channel
# default 3.0
#BW_CHANNEL=42880000
# 42.88m/7=6125714; use profiles_4k_async to get the 1,1.5,...,7 ratio
#BW_CHANNEL=6125714

# use the highest bitrate 16384QAM(8K FFT sync) as the base bitrate
##BW_CHANNEL=2158700000
# use the lowest bitrate QPSK(4K FFT async) as the base bitrate
BW_CHANNEL=282800000

# the number of profiles (1 profile means PF == DRR)
NUMBER_PROFILES=2

# the profile set
#NS2_PROFILE="profiles_4k_async"
#NS2_PROFILE="profiles_4k_sync"
#NS2_PROFILE="profiles_8k_async"
#NS2_PROFILE="profiles_8k_sync"
NS2_PROFILE="profiles_4k_async"

# init the profiles to low profiles
FLG_INIT_PROFILE_LOW=1
# init the profiles to high profiles
FLG_INIT_PROFILE_HIGH=0
# init the profiles to interval profiles
FLG_INIT_PROFILE_INTERVAL=0

# if change half of the flows to highest profile at the middle
#FLG_CHANGE_PROFILE_HIGH=1
FLG_CHANGE_PROFILE_HIGH=1
# change 1/3 time length of the profiles of the flows to low profile
FLG_CHANGE_PROFILE_LOW=0

# the # of nodes in the simulations
#list_nodes_num=(2 4 8 16 256)
#list_nodes_num=(1 2 4 8 16 32 64 128)
#list_nodes_num=(1 3 6 12 24 48 96 192 384)
#list_nodes_num=(1 3 5 7 9 11)
list_nodes_num=(1 3 6 12 24 48 96)

# the scheduler list
list_schedules=("PF")
list_schedules=("PF" "DRR")
#list_schedules=("PF" "DRR" "FCFS" "ARED" "CODEL" "PIE" "FSAQM" "FSAQMDC" "SFQCODEL" "BBAQM" )
list_schedules=("PF" "DRR" "FCFS" "ARED" "CODEL" "PIE" )

list_types=("udp" "tcp" "has" "udp+has" "tcp+has")
