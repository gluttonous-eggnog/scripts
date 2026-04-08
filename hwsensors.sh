#!/usr/bin/env bash

sensors_output=$(sensors)

printf "%s\n" " +------------------------------------------------------------+"
printf " |=\033[41m AMD Ryzen 9800X3D \033[0m========================================|\n"
printf " |                                    |    \033[36mMIN\033[0m    |    \033[35mMAX\033[0m    |\n"
echo "$sensors_output" | awk '
    /^CPU:/ {
        min_value = substr($(NF-3), 1, length($(NF-3)) - 1);
        max_value = substr($(NF-0), 1, length($(NF-0)) - 1);
        printf " | CPU:  \t%14s%11s%7s%5s%7s  |\n", $2, " ", min_value, " ", max_value
    }
    /^(Tctl:|Tccd1)/ { printf " | %s\t%14s%32s|\n", $1, $2, " " }'
printf "%s\n" " +------------------------------------------------------------+"
printf " |= \e[31mPowerColor Reaper AMD Radeon RX 9070\e[0m =====================|\n"
echo "$sensors_output" | awk '
    /^vddgfx:/ {
        printf " | GPU Core (VDDGFX):%7s %-2s%31s|\n", $2, $3, " "
    }
    /^fan1:/ {
        printf " | Fan RPM:%17s RPM%30s|\n", $2, " "
    }
    /^edge:/{
        printf " | GPU Temp:%18s%32s|\n", $2, " "
    }
    /^junction:/ {
        printf " | GPU Hot Spot:%14s%32s|\n", $2, " "
    }
    /^mem:/ {
        printf " | Memory Temp:%15s%32s|\n", $2, " "
    }
    /^PPT:/ {
        printf " | PPT:%21s %-2s%31s|\n", $2, $3, " "
    }
    /^sclk:/ {
        printf " | GPU Clock:%15s %-3s%30s|\n", $2, $3, " "
    }
    /^mclk:/ {
        printf " | MEM Clock:%15s %-3s%30s|\n", $2, $3, " "
    }'
printf "%s\n" " +------------------------------------------------------------+"
printf " |= \033[33mG.Skill FlareX5 32Gb [2x16Gb] DDR5 6000 MHz\033[0m ==============|\n"
echo "$sensors_output" | awk '/^DIMM/ {
    printf " | DIMM A/B Temp:%13s%32s|\n", $2, " "
}'
printf "%s\n" " +------------------------------------------------------------+"
printf " |= \033[33mCrucial T500 1Tb [M.2 PCIe Gen4]\033[0m =========================|\n"
echo "$sensors_output" | awk '/^NVMe/ {
    printf " | NVMe Temp:%17s%32s|\n", $3, " "
}'
printf "%s\n" " +------------------------------------------------------------+"
printf " |= \033[33mASRock PG-B650E-ITX\033[0m ======================================|\n"
printf " |                                    |    \033[36mMIN\033[0m    |    \033[35mMAX\033[0m    |\n"
echo "$sensors_output" | awk '
    /^Vcore:/ {
        printf " | %s\t%12s %-2s%8s%7s V   %7s V  |\n", $1, $2, $3, " ", $(NF-5), $(NF-1)
    }
    index($0, "5.0V") || index($0, "12.0V") || index($0, "VDDCR") || index($0, "VDD_") || index($0,  "3.3V") || index($0, "DRAM") {
        printf " | %s\t%12s %-2s%9s%6s V %9s V  |\n", $1, $2, $3, " ", $(NF-5), $(NF-1)
    }
    /^(CPU Fan|Chassis)/ {
        printf " | %s %s:\t%12s RPM%10s%s\t      %s    |\n", $1, $2, $4, " ", $(NF-5), $(NF-1)
    }
    /^Water Pump:/ {
        printf " | Water Pump:\t%12s RPM%10s%-5s\t%5s%5s    |\n", $3, "", $(NF-5), " ", $(NF-1)
    }
    index($0, "M/B:") || index($0, "VRM:") {
        min_value = substr($(NF-3), 1, length($(NF-3)) - 1);
        max_value = substr($(NF-0), 1, length($(NF-0)) - 1);
        printf " | %s\t%22s%11s%7s%5s%7s  |\n", $1, $2, " ", min_value, " ", max_value
    }'
printf "%s\n" " +------------------------------------------------------------+"
