#!/bin/bash
#
# transfer to nersc single dtn pair and different procs and streams
#
# Usage:
#     run_alex.sh [-T] <prefix>
#     -T:  print run command but don't run tests 


set -u 

one_pair() {

    local logdir=$1
    local logprefix=$2

    # use 1 and 2 bbcp procs with different nstreams
    procs_cfg[1]="1 2 4 8 16"
    #procs_cfg[2]="1 2 4"
    
    start=$(date +%s)
    for nprocs in ${!procs_cfg[@]} ; do
        for nstream in ${procs_cfg[${nprocs}]} ; do
            cfg=bbcpConfigs/stream_${nstream}.cfg
            opts="--logdir ${logdir} --config ${cfg}"        
            ${TEST} ${trans} ${opts} --prefix ${logprefix} "${nprocs}*3-3"
            ${TEST} sleep 15
            ${TEST} ${trans} ${opts} --prefix ${logprefix} --reverse "${nprocs}*3-3"
            ${TEST} sleep 15            
        done
    done
}


many_pairs() {

    local logdir=$1
    local logprefix=$2
    
    opts="--logdir ${logdir} --config bbcpConfigs/stream_4.cfg"

    ${TEST} ${trans} ${opts} --prefix ${logprefix} "1-1,2-2,3-3,4-4"
    ${TEST} sleep 15
    ${TEST} ${trans} ${opts} --prefix ${logprefix} --reverse "1-1,2-2,3-3,4-4"
    ${TEST} sleep 15
    #${TEST} ${trans} ${opts} --prefix ${logprefix} "2*1-1,2*2-2,2*3-3,2*4-4"
    #${TEST} ${trans} ${opts} --prefix ${logprefix} --reverse "2*1-1,2*2-2,2*3-3,2*4-4"
}


TEST=
while getopts :T OPT; do
    case $OPT in
        T|+T) TEST=echo ;;
        *)
            sed -n -e '2,/^[^#]\|^$/ s/^#//p' $0
            exit 2
    esac
done
shift $(( OPTIND - 1 ))
OPTIND=1


prefix=${1:?}
logdir=logs/repeat_v1
trans=./FileTransferTools/run_transfers.py


while [ 1 ] ; do

    start=$(date +%s)
    
    one_pair ${logdir} ${prefix}_one

    many_pairs ${logdir} ${prefix}_mny
    
    
    if [[ -e /cds/home/w/wilko/projects/transfers/lastmile/STOPRUN ]] ; then
        echo "Found stop run"
        break
    fi
    wait=$(( start + 2*3600 - $(date +%s) ))
    echo "Wait ${wait}"
    [[ ${wait} -gt 0 ]] && sleep ${wait}
done
