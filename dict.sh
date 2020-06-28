#!/bin/bash

declare IMPORTDIR=$(cd `dirname ${BASH_SOURCE[0]}` && pwd)
source $IMPORTDIR/out.sh
source $IMPORTDIR/strings.sh


DELIMITER=,

function dict::getdict(){
    local d=${1:-'_DICT'};d="$d[@]"
    printf "%s\n" "${!d}"
}

#@param $1 k
#@param $2 v
#@param $3 dict
function dict::set(){
    local dn=${3:-'_DICT'}
    local d;IFS=$'\n' read -d $'\0' -ra d <<< "$(dict::getdict "$dn")"
 
    local k=$1
    local v=$2
    d+=("$(printf "%s$DELIMITER%s" "$k" "$v")")
    
    local i j
    for i in ${!d[@]};do true;done
    for j in ${!d[@]};do
        local dk dv
        #IFS=$DELIMITER read -r dk dv <<< "${d[j]}"
        dk="${d[j]%%,*}"
        dv="${d[j]#*,}"
        if [ "$k" == "$dk" ]&&[ "$j" -ne "$i" ];then
            d[$j]="$(printf "%s$DELIMITER%s" "$k" "$v")"
            unset 'd[i]'
            break
        fi
    done
    
    eval "$dn"'=("${d[@]}")'
}

#@param $1 k
#@param $2 dict
function dict::get(){
    local d;IFS=$'\n' read -d $'\0' -ra d <<< "$(dict::getdict "$2")"   
 
    local k=$1 
    for v in "${d[@]}";do
        local dk dv
        #IFS=$DELIMITER read -r dk dv <<< "$v"
        dk="${v%%,*}"
        dv="${v#*,}"
        if [ "$k" == "$dk" ];then
            printf '%s\n' "$dv"
            return
        fi
    done
    return 1
}

#@param $1 k
#@param $2 dict
function dict::del(){
    local dn=${2:-'_DICT'}
    local d;IFS=$'\n' read -d $'\0' -ra d <<< "$(dict::getdict "$dn")"
   
    local k=$1 
    for i in ${!d[@]};do
        local dk dv
        #IFS=$DELIMITER read -r dk dv <<< "${d[i]}"
        dk="${d[i]%%,*}"
        dv="${d[i]#*,}"
        if [ "$k" == "$dk" ];then
            unset 'd[i]'  
        fi
    done
    eval "$dn"'=("${d[@]}")'
}

#@param $1 dict
function dict::keys(){
    local d;IFS=$'\n' read -d $'\0' -ra d <<< "$(dict::getdict "$1")"
  
    for v in "${d[@]}";do
        local dk dv
        #IFS=$DELIMITER read -r dk dv <<< "$v"
        dk="${v%%,*}"
        dv="${v#*,}"
        printf '%s\n' "$dk"
    done
}

#@param $1 dict
function dict::debug(){
    local dn=${1:-'_DICT'}
    local d;IFS=$'\n' read -d $'\0' -ra d <<< "$(dict::getdict "$dn")"
    for v in "${d[@]}";do
        local dk dv
        #IFS=$DELIMITER read -r dk dv <<< "$v"
        dk="${v%%,*}"
        dv="${v#*,}"
        out::debug "$(printf '%s%-10s%s\n' "$dn" "[$dk]" "=$dv")"
    done
}


