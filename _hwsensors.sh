#!/usr/bin/env bash

_stroutput=$(sensors)
_nvoutput=$(nvidia-smi -q -d MEMORY,TEMPERATURE,POWER,CLOCK)

printf "+--------------------------------------------------------+\r
|== AMD Ryzen 9 7940HS w/ Radeon 780M iGPU ==============|\n"
awk '/^cpu MHz/ {
    if($NF > max) {
        max = $NF
    }
} END {printf "| CPU Clock:%27s%.3f GHz%9s|\n", " ", max / 1000, " "}' /proc/cpuinfo
echo "$_stroutput" | awk '/^Tctl/ { printf "| CPU Tctl:%35s%11s|\n", $2, " " }'
echo "$_stroutput" | awk '
    /^edge/ {
        printf "| iGPU Edge:%34s%11s|\n", $2, " "
    }
    /^vddgfx/ {
        printf "| iGPU Core (VDDGFX):%23s %-2s%10s|\n", $2, $3, " "
    }
    /^sclk/ {
        printf "| iGPU Clock:%31s %3s%9s|\n", $2, $3, " " 
    }
    /^PPT/ {
        printf "| PPT:             (Avg = %5s %2s%10s %-2s%10s|\n", $6, $7, $2, $3, " " 
    }'
printf "+--------------------------------------------------------+\r
|== 32Gb (2x16Gb) DDR5 Crucial [5600 MT/s] ==============|\n"
echo "$_stroutput"s | awk '/^spd5118/ {
    getline
    getline
    printf "| DIMM:%39s%11s|\n", $2, " "
}'
printf "+--------------------------------------------------------+\r
|== Crucial P310 Gen4 NVMe M.2 ==========================|\n"
echo "$_stroutput" | awk '/^Composite/ {
    printf "| Temperature:%32s%11s|\n", $2, " "
}'
printf "+--------------------------------------------------------+\r
|== NVIDIA 4070 Laptop dGPU 8Gb =========================|\n"
echo "$_nvoutput" | awk '/   Temperature/{
for(i=0;i<2;i++) {
    getline;
    split($0, arr, ":");
    printf "|%8s%s %s:%19s%4s%11s|\n", " ", $2, $3, " ", arr[2], " "
    }
}'
printf "| GPU POWER:                                             |\n"
echo "$_nvoutput" | awk '
    /GPU Power Readings/{
        found=1;
        next
    }
    found && /Average Power Draw|Current Power Limit|Requested Power Limit/ {
        split($0, arr, ":");
        printf "|%8s%s %s %s:\t%12s %s%11s|\n", " ", $1, $2, $3, $5, $6 ," "
        next
    }
    found && /Instantaneous Power Draw/ {
        printf "|%8s%s %s %s:%10s %s%11s|\n", " ", $1, $2, $3, $5, $6 ," "
        next
    }
    /Power Samples/{
        found=0
}'

printf "| CLOCKS:                                                |\n"
echo "$_nvoutput" | awk '/   Clocks/{
    for(i=0;i<4;i++){
        getline;
        split($0, arr, ":");
        printf "|%8s%-20s%19s%9s|\n", " ", $1, arr[2], " "
    }
}'
printf "+--------------------------------------------------------+\n"
