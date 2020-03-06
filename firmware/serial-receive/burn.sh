#!/bin/env bash
set -e

read -p "Place EVEN ROM in burner"
minipro -p AT28C64B -s -w rom_even.bin

read -p "Place ODD ROM in burner"
minipro -p AT28C64B -s -w rom_odd.bin

