#!/bin/bash

declare IMPORTDIR=$(cd `dirname ${BASH_SOURCE[0]}` && pwd)
source $IMPORTDIR/out.sh
source $IMPORTDIR/dict.sh
source $IMPORTDIR/strings.sh
source $IMPORTDIR/arrays.sh

#
# The argparse module is used to parse the command line arguments of a procedure.
# Command line arguments take the following forms: option(-a),
# option with argument (-b foo, -bfoo), multiple options (-ab foo),
# long option (--alpha), long option with argument (--beta foo, --beta=foo),
# positional (foo), and end of options (--).
# Some of the aforelisted forms each can take more than one meanings,
# e.g., an option -a could represent either a Boolean flag or an incremental value.
# The procedure defines what arguments it needs and how it needs them, 
# then argparse parses command line arguments according to what has been defined.
# The defined arguments are stored for retrieval when successfully parsed,
# otherwise invalid ones are reported. 
#
# Both built in getopts and BSD getopt do not include long options.
# This module is a Bash implementation without using getopt(s).
# White space characters are preserved.
# Shell arguments are stored in an array, and thereafter parsed using the array.
# Dash is an invalid (non-leading, non-argument) character for options, e.g. -a-.
# All defined arguments are optional (as opposed to required).
# Parsing ends upon all shell arguments have been consumed, if no error occured.
# An error occurs when: a (long) option is not recognised,
# a (long) option lacks its argument (if it should have one),
# more than the number of defined positional arguments are given, 
# or options string contains the aforementioned invalid dash.
# There are no constraints on the ordering of arguments,
# except when end of options (--) is present.
#
# Validation against constraints takes the literal meaning of each constraint,
# and fails when a constraint is violated by non-conforming argument(s).
# Usage text generation is opinionated, because it is not deterministic,
# e.g., if -a and -b are exclusive, whether both of them can be omitted is not defined.
#
# @see argparse::example
#



argparseSTORETRUE='storetrue'
argparseCOUNT='count'
argparseREQUIRED='required'
argparseEXCLUSIVE='exclusive'

# @param $1 key
# @param $2 action
function argparse::add(){
    local k=$1
    local a=$2

    dict::set "$k" "$a" '_ARGS'
}

# @param $1 key
function argparse::get(){
    local k=$1
    local v;v="$(dict::get "$k" '_PARSED')"
    if [ $? -ne 0 ];then
        return 1
    else
        printf '%s' "$v"
    fi   
}

# @param $@ arguments
function argparse::parse(){
   
    if ! [ "$#" -gt 0 ];then
        argparse::_validateconstraints
        return
    fi

    local ks
    IFS=$'\n' read -d $'\0' -ra ks <<< "$(dict::keys '_ARGS')"
    
    local -a t1 t0 t2
    for k in "${ks[@]}";do
        if [ "${k:0:2}" == '--' ];then
            t2+=("$k")
        elif [ "${k:0:1}" == '-' ];then
            t1+=("$k")
        else
            t0+=("$k")
        fi
    done
     
    local getopt='t'
    local -a args=("$@")
    
    while true;do
        if ! [ "${#args[@]}" -gt 0 ];then
            break
        fi
        if [ "$getopt" == 't' ];then
            if [ "${args[0]}" == '--' ];then
                getopt=''
                unset 'args[0]'
                continue
            fi 
            if [[ ${args[0]} =~ ^--.+$ ]];then
                ! argparse::_parset2||continue

            elif [[ ${args[0]} =~ ^-.+$ ]];then
                ! argparse::_parset1||continue
            fi
           
            if [[ ${args[0]} =~ ^-.*$ ]];then 
                out::error 'invalid argument' "${args[0]}"
                argparse::_printusage 
                exit
            fi
        fi
     
        ! argparse::_parset0||continue
        out::error 'invalid argument' "${args[0]}"
        argparse::_printusage 
        exit 
    done
    argparse::_validateconstraints
}

function argparse::addconstraint(){
    _CONSTRAINTS+=("$(strings::join "$@")")
}

function argparse::setusage(){
    _USAGE="$1"
}

function argparse::_validateconstraints(){
    [ "${#_CONSTRAINTS[@]}" -gt 0 ]||return    
   
    local ks
    IFS=$'\n' read -d $'\0' -ra ks <<< "$(dict::keys '_PARSED')"
    
    for v in "${_CONSTRAINTS[@]}";do
        local -a args
        strings::split "$v" 'args'
        case "${args[0]}" in        
            $argparseREQUIRED)
                args=("${args[@]:1}")
                local -a c;arrays::difference 'args' 'ks' 'c'
                arrays::removeduplicatestrings 'c'
                if [ "${#c[@]}" -gt 0 ];then
                    out::error 'constraint violation' "required argument(s): ${c[*]}"
                    argparse::_printusage 
                    exit
                fi
                ;;
            $argparseEXCLUSIVE)
                args=("${args[@]:1}")
                local -a c;arrays::intersection 'args' 'ks' 'c'
                arrays::removeduplicatestrings 'c'
                if [ "${#c[@]}" -gt 1 ];then
                    out::error 'constraint violation' "exclusive arguments: ${c[*]}"
                    argparse::_printusage 
                    exit 
                fi
                ;;
            *)
                ;;
        esac
    done
}

function argparse::_printusage(){
    local msg
    if [ -n "${_USAGE}" ];then
        msg="${_USAGE}"
    else
        msg="$(argparse::_generateusage)"
    fi
    out::info "$msg"
    #local l
    #while IFS='' read -r -d$'\n' l;do
    #    out::info "$l"
    #done <<<"$msg"
}

function argparse::_generateusage(){
    local -a p0 p1 p2 p3 p4 p5 p8

    local -a required exclusive
    for v in "${_CONSTRAINTS[@]}";do
        local -a args
        strings::split "$v" 'args'
        case "${args[0]}" in        
            $argparseREQUIRED)
                args=("${args[@]:1}")
                required=("${required[@]}" "${args[@]}")
                ;;
            $argparseEXCLUSIVE)
                args=("${args[@]:1}")
                exclusive=("${exclusive[@]}" "${args[@]}")
                for i in "${!args[@]}";do
                    local action="$(dict::get "${args[i]}" '_ARGS')"
                    if [[ ${args[i]} =~ ^-.*$ ]]&&[ -z "$action" ];then
                        args[i]+=' arg'
                    fi                  
                done
                p8+=("$(DELIMITER=' | ' strings::join "${args[@]}")")
                ;;
            *)
                ;;
        esac
    done
    
    local -a ks
    IFS=$'\n' read -d $'\0' -ra ks <<< "$(dict::keys '_ARGS')"
    arrays::difference 'ks' 'exclusive' 'ks' 
    
    for v in "${ks[@]}";do
        local action="$(dict::get "$v" '_ARGS')"
        if [ "${v:0:2}" == '--' ];then
            if [ -z "$action" ];then
                p5+=("${v:2}")
            else
                p4+=("${v:2}")
            fi
        elif [ "${v:0:1}" == '-' ];then
            if [ -z "$action" ];then
                p3+=("${v:1}")
            else
                p2+=("${v:1}")
            fi
        else
            if arrays::contains 'required' "$v";then
                p0+=("$v")
            else
                p0+=("[$v]")
            fi
        fi
    done
    
    local msg
    ! [ "${#p2[@]}" -gt 0 ]||msg+="[-$(printf '%s' $(IFS=$'\n' sort <<<"${p2[*]}"|uniq|xargs))] "
    ! [ "${#p8[@]}" -gt 0 ]||msg+="$(printf '[%s] ' "${p8[@]}")"
    ! [ "${#p3[@]}" -gt 0 ]||msg+="$(printf '[-%s arg] ' "${p3[@]}")"
    ! [ "${#p4[@]}" -gt 0 ]||msg+="$(printf '[--%s] ' "${p4[@]}")"
    ! [ "${#p5[@]}" -gt 0 ]||msg+="$(printf '[--%s arg] ' "${p5[@]}")"
    ! [ "${#p0[@]}" -gt 0 ]||msg+="$(printf '%s ' "${p0[@]}")"
    msg="$(strings::trimspace "$msg")"

    msg="$(cat <<EOF
Usage:
    command $msg
EOF
)"

    printf '%s' "$msg"
}

function argparse::_parset0(){
    set -- "${args[@]}"
    for i in "${!t0[@]}";do
        dict::set "${t0[i]}" "$1" '_PARSED'
        unset 't0[i]'
        shift
        args=("$@");return
    done
    return 1
}

function argparse::_parset2(){
    set -- "${args[@]}"
    for k in "${t2[@]}";do
        if [ "$1" == "$k" ];then
            local action="$(dict::get "$k" '_ARGS')"
            case $action in
                $argparseSTORETRUE)
                    dict::set "$k" 't' '_PARSED'
                    shift
                    args=("$@");return
                    ;;
                $argparseCOUNT)
                    local c="$(dict::get "$k" '_PARSED')"
                    dict::set "$k" $((c+1)) '_PARSED'
                    shift
                    args=("$@");return
                    ;;  
                *)
                    if [ "$#" -gt 1 ];then
                        dict::set "$k" "$2" '_PARSED'
                        shift 2
                        args=("$@");return
                    else
                        out::error 'invalid argument' "$1"
                        argparse::_printusage 
                        exit
                    fi
                    ;;
            esac
        fi
        if [[ $1 == "$k="* ]];then
            local action="$(dict::get "$k" '_ARGS')"
            if [ -n "$action" ];then
                out::error 'invalid argument' "$k"
                argparse::_printusage 
                exit
            fi
            dict::set "$k" "${1#*=}" '_PARSED'
            shift
            args=("$@");return
        fi
    done
    return 1
}

function argparse::_parset1(){
    set -- "${args[@]}"
    for k in "${t1[@]}";do
        if [ "${1:0:2}" == "$k" ];then
            local action="$(dict::get "$k" '_ARGS')"
            case $action in
                $argparseSTORETRUE)
                    dict::set "$k" 't' '_PARSED'
                    if [ -z "${1:2}" ];then
                        shift
                    else
                        if [ "${1:2:1}" == '-' ];then
                            out::error 'invalid argument' "$1"
                            argparse::_printusage 
                            exit
                        fi
                        set -- "${1:0:1}${1:2}" "${@:2}"
                    fi
                    args=("$@");return
                    ;;
                $argparseCOUNT)
                    local c="$(dict::get "$k" '_PARSED')"
                    dict::set "$k" $((c+1)) '_PARSED'
                    if [ -z "${1:2}" ];then
                        shift
                    else
                        if [ "${1:2:1}" == '-' ];then
                            out::error 'invalid argument' "$1"
                            argparse::_printusage 
                            exit
                        fi
                        set -- "${1:0:1}${1:2}" "${@:2}"
                    fi
                    args=("$@");return
                    ;;  
                *)
                    if [ -z "${1:2}" ];then
                        if [ "$#" -gt 1 ];then
                            dict::set "$k" "$2" '_PARSED'
                            shift 2
                            args=("$@");return
                        else
                            out::error 'invalid argument' "$1"
                            argparse::_printusage 
                            exit
                        fi 
                    else
                        dict::set "$k" "${1:2}" '_PARSED'
                        shift
                        args=("$@");return
                    fi
                    ;;
            esac
        fi  
    done
    return 1
}
function argparse::debug(){
    dict::debug '_PARSED'
}


function argparse::example()(
    argparse::add '-a' 'storetrue'
    argparse::add '-b' 'count'
    argparse::add '-o'
    argparse::add '--foo'
    argparse::addconstraint 'required' '-a'
    argparse::addconstraint 'exclusive' '-o' '--foo'
    argparse::parse "$@"
    argparse::debug
)

function argparse::getopt(){
    local args;args=`getopt -abo: $*`    
    out::debug "$(printf 'errcode:%s' "$?")"
    set -- $args
    local len=$#
    for ((i=0;i<$len;i++));do
        let j=i+1
        out::debug "$(printf '$%s:%s' $j "${!j}")"
    done
}

function argparse::getopts(){
    local arg
    while getopts :abo: arg;do
        case $arg in
            \?) 
                out::error "$(printf '%s:%s' "-$OPTARG" 'invalid')"
                ;;
            :) 
                out::error "$(printf '%s:%s' "-$OPTARG" 'required')"
                ;;
            *) 
                out::debug "$(printf '%s:%s' "-$arg" "$OPTARG")"
                ;;
        esac
    done
    shift $((OPTIND-1))
    local len=$#
    for ((i=0;i<$len;i++));do
        let j=i+1
        out::debug "$(printf '$%s:%s' $j "${!j}")"
    done   
}



