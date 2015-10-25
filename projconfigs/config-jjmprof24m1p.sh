#!/bin/sh
# config file for the simulations

# the test information to be showed
MSG_TITLE="DOCSIS 3.1 Profiles"
MSG_DESCRIPTION="D31 24.5MHz channel, with 1 profile, test competing UDP/TCP flows."
PREFIX="jjmprof24m1p"

# the message log file
#FN_LOG="log.txt"
FN_LOG="/dev/null"

# control if plot packet scheduling time figures
USE_MEDIUMPACKET=1

# the stop time for the test
TIME_STOP=160.2

# the start time for measure the throughput
TIME_START=5

# the number of profiles (1 profile means PF == DRR)
NUMBER_PROFILES=1

# the maximum bitrate of the channel
# default 3.0
#BW_CHANNEL=42880000
# 42.88m/7=6125714; use profiles_4k_async_192m to get the 1,1.5,...,7 ratio
# 42.88m/6=7146667
#BW_CHANNEL=7146667

# use the highest bitrate 16384QAM(8K FFT sync) as the base bitrate (192MHz channel)
##BW_CHANNEL=2158700000
# use the lowest bitrate QPSK(4K FFT async) as the base bitrate (192MHz channel)
#BW_CHANNEL=282800000

# use the lowest bitrate QPSK(4K FFT async) as the base bitrate (97MHz channel)
#BW_CHANNEL=135800000

# use the lowest bitrate QPSK(4K FFT async) as the base bitrate (49.5MHz channel)
#BW_CHANNEL=62300000

# use the lowest bitrate QPSK(4K FFT async) as the base bitrate (24.5MHz channel)
BW_CHANNEL=23600000

# the profile set for 192MHz channel
#NS2_PROFILE="profiles_4k_async_192m"
#NS2_PROFILE="profiles_4k_sync_192m"
#NS2_PROFILE="profiles_8k_async_192m"
#NS2_PROFILE="profiles_8k_sync_192m"

# the profile set for 24.5MHz channel
#NS2_PROFILE="profiles_4k_async_24m"
#NS2_PROFILE="profiles_4k_sync_24m"
#NS2_PROFILE="profiles_8k_async_24m"
#NS2_PROFILE="profiles_8k_sync_24m"
NS2_PROFILE="profiles_4k_async_24m"

# init the profiles to low profiles
FLG_INIT_PROFILE_LOW=0
# init the profiles to high profiles
FLG_INIT_PROFILE_HIGH=1
# init the profiles to interval profiles
FLG_INIT_PROFILE_INTERVAL=0

# if change half of the flows to highest profile at the middle
#FLG_CHANGE_PROFILE_HIGH=1
FLG_CHANGE_PROFILE_HIGH=0
# change 1/3 time length of the profiles of the flows to low profile
FLG_CHANGE_PROFILE_LOW=0

# the # of nodes in the simulations
#LIST_NODE_NUM="2 4 8 16 256"
#LIST_NODE_NUM="1 2 4 8 16 32 64 128"
#LIST_NODE_NUM="1 3 6 12 24 48 96 192 384"
#LIST_NODE_NUM="1 3 5 7 9 11"
LIST_NODE_NUM="1 3 6 12 24 48 96"

# the scheduler list
#LIST_SCHEDULERS="PF DRR FCFS ARED CODEL PIE FSAQM FSAQMDC SFQCODEL BBAQM"
LIST_SCHEDULERS="DRR SFQCODEL PF CODEL PIE FCFS ARED"

# list of flow types
#LIST_TYPES="udp tcp has udp+has tcp+has"
LIST_TYPES="udp tcp"
