
#Playback buffer capacity: This is configured in units of seconds.  The client issues requests to maintain the playback buffer within an operating range defined by two internal parameters, Highwatermark and Lowwatermark. The default setting of the playback buffer capacity is 90 seconds.
#This is the playback buffer in seconds
#Note: a more reasonable value is 90 seconds
#set vodapp_playback_buffer_capacity 240
#set clientbuffersize 240
#set vodapp_playback_buffer_capacity 90

set vodapp_playback_buffer_capacity 60
#set vodapp_playback_buffer_capacity 120
#set vodapp_playback_buffer_capacity 30
#set clientbuffersize $vodapp_playback_buffer_capacity
#set DASHMODE 1

#set vodapp_playback_buffer_capacity 512
set DASHMODE 2

set aavginterval 0.5
set aavgdelta 0.80
set startingServerRate 100000000
set MAX_CONTENT_ENCODING_RATE 3750000



# Number of outstanding client requests: This determines the maximum number of requests that can be outstanding at any given time. The default setting is 2 segments.
set vodapp_outstanding_requests 2

# Segment size: This determines the granularity of the data exchanges between the DASH server and the client. The default is 2.5 seconds.
set vodapp_segment_size 10.0
#set vodapp_segment_size 12.5
#set vodapp_segment_size 2.0

# Bitrate Reduction Adaptation Threshold : This tunes the client’s sensitivity to changes in observed reduction in available bandwidth. 0.0 ~ 1.0 (0% ~ 100%)
# Bitrate Increase Adaptation Threshold : This tunes the client’s sensitivity to changes in observed reduction in available bandwidth. 0.0 ~ 1.0 (0% ~ 100%)
#As the increase ratio  approaches  -1 it gets more aggressive in switching to higher bitrates
set vodapp_ratio_threshold_increase -0.2
#As the reduction ratio approaches -1, it gets more sensitive to drops in BW
#set vodapp_ratio_threshold_reduction 0.15
set vodapp_ratio_threshold_reduction -0.5

# Discrete bitrate encoder options: The range of possible bitrate encoder values is set as follows (in units of bps)
# Bitrate Encoder Value Options: right now these are hardcoded to something like:  768000, 1500000, 2200000, 2600000, 3200000, 3800000, 4200000, 4800000 .
# But are some of our simulations will consider what happens as the range increases -  like perhaps {1Mbps….10 Mbps}.  So what’s the best way to configure this?
#set vodapp_bitrates_list [list 768000 1500000 2200000 2600000 3200000 3800000 4200000 4800000]
#set vodapp_bitrates_list [list 500000 1000000 1800000 2200000 2800000 3400000 3800000 4200000]
#set vodapp_bitrates_list [list 4200000 4200000 4200000 4200000 4200000 4200000 4200000 4200000]
#BASE
set vodapp_bitrates_list [list 64000 128000 500000 1000000 1500000 2600000 3500000 3750000 4200000]
#EXPERIMENTAL 1
#set vodapp_bitrates_list [list 500000 1000000 2000000 3000000 4000000 5000000 6000000 7000000 8000000]
#EXPERIMENTAL 2
#set vodapp_bitrates_list [list 600000 1050000 1500000 1950000 2400000 2850000 3300000 3750000 4200000]

#Low Def
set vodapp_bitrates_list_ld  [list 2200000 2200000 2200000 2200000 2200000 2200000 2200000  2200000]

#Medium Def
set vodapp_bitrates_list_md  [list 3400000 3400000 3400000 3400000 3400000 3400000 3400000 3400000]

#Standard Def
set vodapp_bitrates_list_sd  [list 4200000 4200000 4200000 4200000 4200000 4200000 4200000 4200000]

# High Def
#set vodapp_bitrates_list_hd  [list 5250000 5250000 5250000 5250000 5250000 5250000 5250000 5250000]
set vodapp_bitrates_list_hd  [list 8400000 8400000 8400000 8400000 8400000 8400000 8400000 8400000]

#Ultra High Def
set vodapp_bitrates_list_uhd  [list 16800000 16800000 16800000 16800000 16800000 16800000 16800000 16800000]

# the ratio of the received/max size of the block fetch from buffer by player, default 0.30, value range 0.0 ~ 1.0 (0% ~ 100%)
set vodapp_player_fetch_ratio_threshold 0.30

#Set to 1/24 = 0.04167
#set vodapp_player_interval 0.04167
#set vodapp_player_interval $vodapp_segment_size
set vodapp_player_interval [expr $vodapp_segment_size / 4]

set vodapp_player_threshold [expr 2 * $vodapp_segment_size]

# AdaptationSensitivity: the sensitivity of the switching:
# we use delay time to smooth the # of switching, real switching delay = (1 - adaptation_sensitivity) * 10 * switching_interval + adaptation_sensitivity * switching_interval / 10
# we set it to 0.909 to make sure the real switching_interval ~= switching_interval
set vodapp_adaptation_sensitivity 0.909


# (Client only) the time to detected the slop of lower bitrate. The bitrates detected in this interval should alway lower than the previous one before to switch to lower bitrate
set vodapp_switching_interval_increase 2.0
set vodapp_switching_interval_reduction 2.0

set vodapp_player_min_stabilize_time 100.0

