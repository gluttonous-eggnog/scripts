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
awk '/^Tctl/ {
        CPUc = sprintf("| CPU Tctl:%35s%11s|", $2, " ")
    }
    /^edge/ {
        iGPUt = sprintf("| iGPU Edge:%34s%11s|", $2, " ")
    }
    /^vddgfx/ {
        iGPUv = sprintf("| iGPU Core (VDDGFX):%23s %-2s%10s|", $2, $3, " ")
    }
    /^sclk/ {
        iGPUc = sprintf("| iGPU Clock:%31s %3s%9s|", $2, $3, " ") 
    }
    /^PPT/ {
        CPUp = sprintf("| PPT:             (Avg = %5s %2s%10s %-2s%10s|", $6, $7, $2, $3, " ") 
    }
    /^spd5118/ {
        getline
        getline
        ddrmem = sprintf("| DIMM:%39s%11s|", $2, " ")
    }
    /^Composite/ {
        nvme = sprintf("| Temperature:%32s%11s|", $2, " ")
    }
    END {
        print CPUc
        print iGPUt
        print iGPUc
        print iGPUv
        print CPUp
        print "+--------------------------------------------------------+"
        print "|== 32Gb (2x16Gb) DDR5 Crucial [5600 MT/s] ==============|"
        print ddrmem
        print "+--------------------------------------------------------+"
        print "|== Crucial P310 Gen4 NVMe M.2 ==========================|"
        print nvme                
    }
    ' <<< "$_stroutput"

printf "+--------------------------------------------------------+\r
|== NVIDIA 4070 Laptop dGPU 8Gb =========================|\n"
awk '
    /GPU Current Temp/{
        split($0, arr, ":");
        printf "|%8s%s %s:%19s%4s%11s|\n", " ", $2, $3, " ", arr[2], " "
    }
    /GPU Power Readings/{
        printf "| GPU POWER:                                             |\n"
        found=1;
        next
    }
    found && /Average Power Draw|Current Power Limit/ {
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
    }
    /   Clocks/{
        print "| CLOCKS:                                                |"
        for(i=0;i<4;i++){
            getline;
            split($0, arr, ":");
            printf "|%8s%-20s%19s%9s|\n", " ", $1, arr[2], " "
        }
    }
' <<< "$_nvoutput"
printf "+--------------------------------------------------------+\n"
