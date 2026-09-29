#!/usr/bin/env bash

sensors_output=$(sensors)
awk '
    /^CPU:/ {
        min_value = substr($(NF-3), 2, length($(NF-3)) - 2);
        max_value = substr($(NF-0), 2, length($(NF-0)) - 2);
        cpudie = sprintf("││ CPU   \t%16s%9s%7s%5s%7s  ││", substr($2, 2), " ", min_value, " ", max_value)
    }
    /^Tctl:/ {
        cputctl = sprintf("││ CPU (Tctl)\t%16s%30s││", substr($2, 2), " ")
    }
    /^Tccd1:/{
        cputccd1 = sprintf("││ CPU CCD1 (Tdie)%14s%30s││", substr($2, 2), " ")
    }
    /^edge:/{
        gputemp = sprintf("││ GPU Temperature %13s%30s││", substr($2, 2), " ")
    }
    /^junction:/ {
        gpuhs = sprintf("││ GPU Hot Spot %16s%30s││", substr($2, 2), " ")
    }
    /^mem:/ {
        gpumem = sprintf("││ GPU Memory Temp %13s%30s││", substr($2, 2), " ")
    }
    /^sclk:/ {
        gpuclk = sprintf("││ GPU FCLK %18s %-3s%28s││", $2, $3, " ")
    }
    /^mclk:/ {
        gpumclk = sprintf("││ GPU Memory Clock %10s %-3s%28s││", $2, $3, " ")
    }
    /^vddgfx:/ {
        gpucore = sprintf("││ GPU Core (VDDGFX) %9s %-2s%29s││", $2, $3, " ")
    }
    /^PPT:/ {
        gpupower = sprintf("││ GPU Power (PPT) %11s %-2s%29s││", $2, $3, " ")
    }
    /^fan1:/ {
        gpufan = sprintf("││ Fan Speed %17s RPM%28s││", $2, " ")
    }
    /^DIMM/ {
        ddr_mem = sprintf("││ DIMM A/B Temperature %8s%30s││", substr($2, 2), " ")
    }
    /^NVMe/ {
        nvme_temp = sprintf("││ NVMe Temperature %12s%30s││", substr($3, 2), " ")
    }
    /^Vcore:/ {
        corev = sprintf("││ %s\t%14s %-2s%6s%7s V   %7s V  ││", substr($1, 1, length($1)-1), $2, $3, " ", substr($(NF-5), 2), substr($(NF-1), 2))
    }
    index($0, "5.0V") || index($0, "12.0V") || index($0, "VDDCR") || index($0, "VDD_") || index($0,  "3.3V") || index($0, "DRAM") {
        voltages[NR] = sprintf("││ %s \t%14s %-2s%7s%6s V %9s V  ││", substr($1, 1, length($1)-1), $2, $3, " ", substr($(NF-5), 2), substr($(NF-1), 2))
    }
    index($0, "M/B:") {
        min_value = substr($(NF-3), 2, length($(NF-3)) - 2);
        max_value = substr($(NF-0), 2, length($(NF-0)) - 2);
        mobo_temp = sprintf("││ M/B Temperature \t%8s%9s%7s%5s%7s  ││", substr($2, 2), " ", min_value, " ", max_value)
    }
    index($0, "VRM:") {
        min_value = substr($(NF-3), 2, length($(NF-3)) - 2);
        max_value = substr($(NF-0), 2, length($(NF-0)) - 2);
        vrm_temp = sprintf("││ VRM Temperature \t%8s%9s%7s%5s%7s  ││", substr($2, 2), " ", min_value, " ", max_value)
    }
    /^CPU Fan/ {
        cpufan = sprintf("││ %s %s \t%14s RPM%8s%s\t      %s    ││", $1, $2, $4, " ", $(NF-5), $(NF-1))
    }
    /^Chassis/ {
        chassisfan = sprintf("││ %s %s \t%14s RPM%8s%s\t      %s    ││", $1, $2, $4, " ", $(NF-5), $(NF-1))
    }
    /^Water Pump:/ {
        waterp = sprintf("││ Water Pump \t%14s RPM%8s%-5s\t%5s%5s    ││", $3, "", $(NF-5), " ", $(NF-1))
    }
    END {
        printf "┌──────────────────────────────────────────────────────────────┐\n"
        printf "│┌─\033[41m AMD Ryzen 7 7800X3D \033[0m──────────────┬───────────┬───────────┐│\n"
        printf "││                                    │    \033[36mMIN\033[0m    │    \033[35mMAX\033[0m    ││\n"
        print cpudie
        print cputctl
        print cputccd1
        printf "│└────────────────────────────────────────────────────────────┘│\n"
        printf "│┌─ \033[31mPowerColor Reaper AMD Radeon RX 9070\033[0m ─────────────────────┐│\n"
        print gputemp
        print gpuhs
        print gpumem
        print gpuclk
        print gpumclk
        print gpucore
        print gpupower
        print gpufan
        printf "│└────────────────────────────────────────────────────────────┘│\n"
        printf "│┌─ \033[33mG.Skill FlareX5 32Gb [2x16Gb] DDR5 6000 MHz\033[0m ──────────────┐│\n"
        print ddr_mem
        printf "│└────────────────────────────────────────────────────────────┘│\n"
        printf "│┌─ \033[33mCrucial T500 1Tb [M.2 PCIe Gen4]\033[0m ─────────────────────────┐│\n"
        print nvme_temp
        printf "│└────────────────────────────────────────────────────────────┘│\n"
        printf "│┌─ \033[33mASRock PG-B650E-ITX\033[0m ──────────────┬───────────┬───────────┐│\n"
        printf "││                                    │    \033[36mMIN\033[0m    │    \033[35mMAX\033[0m    ││\n"
        print corev
        for (v in voltages) {
            print voltages[v]
        }
        printf "│├────────────────────────────────────────────────────────────┤│\n"
        print cpufan
        print waterp
        print chassisfan
        printf "│├────────────────────────────────────────────────────────────┤│\n"
        print mobo_temp
        print vrm_temp
        printf "│└────────────────────────────────────────────────────────────┘│\n"
        printf "└──────────────────────────────────────────────────────────────┘\n"
    }
' <<< "$sensors_output"
