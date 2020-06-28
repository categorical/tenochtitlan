#!/bin/bash

declare IMPORTDIR=$(cd `dirname ${BASH_SOURCE[0]}` && pwd)
source $IMPORTDIR/out.sh
source $IMPORTDIR/strings.sh
source $IMPORTDIR/file.sh

DELIMITER=,

#@param $1 file
function kv::setfile(){
    _KVFILE=$1
}
function kv::getfile(){
    if [ -z "${_KVFILE+foo}" ]||[ ! -f "${_KVFILE}" ];then
        out::error "file not found"
        return 1
    else
        printf "%s" ${_KVFILE}
    fi
}

#@param $1 k
#@param $2 v
function kv::set(){
    local f;f=$(kv::getfile)
    if [ "$?" -ne 0 ];then
        return 1
    fi
    
    local k=$1
    local kescaped=$(strings::escapebresed "$k")
    local v=$2
    # cat foo|tee foo introduces a race condition
    #sed -n '/^'"$kescaped$DELIMITER"'/!p' $f|cat <(cat -) <(printf "%s${DELIMITER}%s\n" "$k" "$v")|tee $f >/dev/null     
    local _temp;_temp=$(file::mktemp)
    [ "$?" -eq 0 ]||return 1
    
    sed -n '/^'"$kescaped$DELIMITER"'/!p' $f \
        |cat <(cat -) <(printf "%s${DELIMITER}%s\n" "$k" "$v") \
        >"$_temp" \
        && cat "$_temp" >"$f"

    [ ! -f "$_temp" ]||rm "$_temp"
}

#@param $1 k
function kv::get(){
    local f;f=$(kv::getfile)
    if [ $? -ne 0 ];then
        return 1
    fi
    local k=$1

    while IFS=$DELIMITER read -d$'\n' -r c0 c1;do
        if [ "$k" == "$c0" ];then
            printf "%s" "$c1"
            return
        fi
    done < "$f"
    return 1
}

#@param $1 k
function kv::del(){
    local f;f=$(kv::getfile)
    if [ $? -ne 0 ];then
        return 1
    fi
    local kescaped=$(strings::escapebresed "$1")
    #sed '/^'"$kescaped$DELIMITER"'/d' $f|tee $f >/dev/null  
    
    local _temp;_temp=$(file::mktemp)
    [ "$?" -eq 0 ]||return 1

    sed '/^'"$kescaped$DELIMITER"'/d' $f >"$_temp" \
        && cat "$_temp" >"$f"

    [ ! -f "$_temp" ]||rm "$_temp"
}

function kv::keys(){
    local f;f=$(kv::getfile)
    if [ $? -ne 0 ];then
        return 1
    fi
    cat "$f"|while IFS=$DELIMITER read -d$'\n' -r c0 c1;do
        printf "%s\n" $c0    
    done|sort|uniq
}




