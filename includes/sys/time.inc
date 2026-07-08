.ifndef _AS_SYS_TIME_INC
.set _AS_SYS_TIME_INC, 1

.equ CLOCK_REALTIME, 0

# Timespec structure offsets
.equ TIMESPEC_tv_sec, 0
.equ TIMESPEC_tv_nsec, 8
.equ TIMESPEC_size, 16

# Timeval structure offsets
.equ TIMEVAL_tv_sec, 0
.equ TIMEVAL_tv_usec, 8
.equ TIMEVAL_size, 16
