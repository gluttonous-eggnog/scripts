#!/usr/bin/env bash

sensors_output=$(sensors)
awk '/^CPU:/ {
        min_value = substr($(NF-3), 2, length($(NF-3)) - 2);
        max_value = substr($(NF-0), 2, length($(NF-0)) - 2);
        cpudie = sprintf("││ CPU   \t%18s%7s%7s%5s%7s  ││", substr($2, 2), " ", min_value, " ", max_value)
    }
    /^Tctl:/ {
        cputctl = sprintf("││ CPU (Tctl)\t%18s%28s││", substr($2, 2), " ")
    }
    /^Tccd1:/{
        cputccd1 = sprintf("││ CPU CCD1 (Tdie)%16s%28s││", substr($2, 2), " ")
    }
    /^edge:/{
        gputemp = sprintf("││ GPU Temperature %15s%28s││", substr($2, 2), " ")
    }
    /^junction:/ {
        gpuhs = sprintf("││ GPU Hot Spot %18s%28s││", substr($2, 2), " ")
    }
    /^mem:/ {
        gpumem = sprintf("││ GPU Memory Temperature %8s%28s││", substr($2, 2), " ")
    }
    /^sclk:/ {
        gpuclk = sprintf("││ GPU Core Clock %14s %-3s%26s││", $2, $3, " ")
    }
    /^mclk:/ {
        gpumclk = sprintf("││ GPU Memory Clock %12s %-3s%26s││", $2, $3, " ")
    }
    /^vddgfx:/ {
        gpucore = sprintf("││ GPU Core (VDDGFX) %11s %-2s%27s││", $2, $3, " ")
    }
    /^PPT:/ {
        gpupower = sprintf("││ GPU Power (PPT) %13s %-2s%27s││", $2, $3, " ")
    }
    /^fan1:/ {
        gpufan = sprintf("││ GPU Fan Speed %15s RPM%26s││", $2, " ")
    }
    /^DIMM/ {
        ddr_mem = sprintf("││ DIMM Temperature (A)(B) %7s%28s││", substr($2, 2), " ")
    }
    /^NVMe/ {
        nvme_temp = sprintf("││ NVMe Temperature %14s%28s││", substr($3, 2), " ")
    }
    /^Vcore:/ {
        corev = sprintf("││ %s\t%16s %-2s%3s│%7s V  │%7s V  ││", substr($1, 1, length($1)-1), $2, $3, " ", substr($(NF-5), 2), substr($(NF-1), 2))
    }
    index($0, "5.0V") || index($0, "12.0V") || index($0, "VDDCR") || index($0, "VDD_") || index($0,  "3.3V") || index($0, "DRAM") {
        voltages[NR] = sprintf("││ %s \t%16s %-2s%3s│ %6s V  │%7s V  ││", substr($1, 1, length($1)-1), $2, $3, " ", substr($(NF-5), 2), substr($(NF-1), 2))
    }
    index($0, "M/B:") {
        min_value = substr($(NF-3), 2, length($(NF-3)) - 2);
        max_value = substr($(NF-0), 2, length($(NF-0)) - 2);
        mobo_temp = sprintf("││ M/B Temperature \t%10s%4s│  %7s%2s│  %7s  ││", substr($2, 2), " ", min_value, " ", max_value)
    }
    index($0, "VRM:") {
        min_value = substr($(NF-3), 2, length($(NF-3)) - 2);
        max_value = substr($(NF-0), 2, length($(NF-0)) - 2);
        vrm_temp = sprintf("││ VRM Temperature \t%10s%4s│  %7s%2s│  %7s  ││", substr($2, 2), " ", min_value, " ", max_value)
    }
    /^CPU Fan/ {
        cpufan = sprintf("││ %s %s \t%16s RPM  │%3s%s\t  │   %s    ││", $1, $2, $4, " ", $(NF-5), $(NF-1))
    }
    /^Chassis/ {
        chassisfan = sprintf("││ %s %s \t%16s RPM  │%3s%s\t  │   %s    ││", $1, $2, $4, " ", $(NF-5), $(NF-1))
    }
    /^Water Pump:/ {
        # issue with cooler master atmos displaying 10000, should only be max 3200
        waterp = sprintf("││ Water Pump \t%16s RPM  │%3s%s\t  │   %s    ││", int($3 / 3.125), "", int($(NF-5) / 3.125), int($(NF-1) / 3.125))
    }
    END {
        printf "╭──────────────────────────────────────────────────────────────╮\n"
        printf "│╭─\033[41m AMD Ryzen 7 9800X3D \033[0m──────────────┬───────────┬───────────╮│\n"
        printf "││                                    │    \033[36mMIN\033[0m    │    \033[35mMAX\033[0m    ││\n"
        print cpudie
        print cputctl
        print cputccd1
        printf "│╰────────────────────────────────────────────────────────────╯│\n"
        printf "│╭─ \033[31mPowerColor Reaper AMD Radeon RX 9070\033[0m ─────────────────────╮│\n"
        print gputemp
        print gpuhs
        print gpumem
        print gpuclk
        print gpumclk
        print gpucore
        print gpupower
        print gpufan
        printf "│╰────────────────────────────────────────────────────────────╯│\n"
        printf "│╭─ \033[33mG.Skill FlareX5 DDR5 6000 MHz 32Gb [2x16Gb]\033[0m ──────────────╮│\n"
        print ddr_mem
        printf "│╰────────────────────────────────────────────────────────────╯│\n"
        printf "│╭─ \033[33mCrucial T500 1Tb [M.2]\033[0m ───────────────────────────────────╮│\n"
        print nvme_temp
        printf "│╰────────────────────────────────────────────────────────────╯│\n"
        printf "│╭─ \033[33mASRock PG-B650E-ITX\033[0m ──────────────┬───────────┬───────────╮│\n"
        printf "││                                    │    \033[36mMIN\033[0m    │    \033[35mMAX\033[0m    ││\n"
        print corev
        for (v in voltages) {
            print voltages[v]
        }
        printf "│╞════════════════════════════════════╪═══════════╪═══════════╡│\n"
        print cpufan
        print waterp
        print chassisfan
        printf "│╞════════════════════════════════════╪═══════════╪═══════════╡│\n"
        print mobo_temp
        print vrm_temp
        printf "│╰────────────────────────────────────┴───────────┴───────────╯│\n"
        printf "╰──────────────────────────────────────────────────────────────╯\n"
    }' <<< "$sensors_output"
