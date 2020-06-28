#!/bin/bash

declare IMPORTDIR=$(cd `dirname ${BASH_SOURCE[0]}` && pwd)

source $IMPORTDIR/out.sh

function import(){
    local d=$IMPORTDIR
    
    for v in "$@";do
        local f=$d/$v.sh
        if [ ! -f "$f" ];then
            out::error "file not found" $f
            return 1
        fi
         
        local varname="IMPORTED$v"       
        [ -z "${!varname+foo}" ]||continue
        
        source "$f"
        if [ $? -eq 0 ];then 
            declare $varname=1
        else
            out::error "failed to import" $f
            return 1
        fi
    done
}

if [ "$#" -ne 0 ] && [ -n "$1" ];then
    import "$@"
fi

