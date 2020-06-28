#!/bin/sh



# [0m clears all colours
# [1m bold
# [3m italic
# [4m underline

xs=('m' '1m' '30m' '1;30m' '31m' '1;31m' \
    '32m' '1;32m' '33m' '1;33m' '34m' '1;34m' \
    '35m' '1;35m' '36m' '1;36m' '37m' '1;37m'\
    '90m' '1;90m' '91m' '1;91m' '92m' '1;92m'\
    '93m' '1;93m' '94m' '1;94m' '95m' '1;95m'\
    '96m' '1;96m')

ys=('40m' '41m' '42m' '43m' '44m' '45m' '46m' '47m')

td='%10s'

echo
printf $td
for y in ${ys[@]};do
    printf $td "\033[$y"
done
echo
for x in ${xs[@]};do
    printf $td "\033[$x"
    for y in ${ys[@]};do
        printf "\033[${x}\033[${y}$td\033[0m" Colour
    done
    echo
done
echo



