#!/usr/bin/env bash
set -e

if [[ -z $ROMDEVICE ]]; then
  echo "ROMDEVICE not set; Please supply the ROM device type!"
else
  echo "Burning ROM device type $ROMDEVICE"

  read -p "Place EVEN ROM in burner"
  minipro -p $ROMDEVICE -s -w rosco_m68k_even.rom

  read -p "Place ODD ROM in burner"
  minipro -p $ROMDEVICE -s -w rosco_m68k_odd.rom
fi

