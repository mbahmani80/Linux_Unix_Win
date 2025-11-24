#!/bin/bash

f_new_checkmk_error_state="01_new_checkmk_error_state.txt"
f_bk2ndreq_but_nodessetup="02_bk2ndreq_but_nodessetup.txt"
v_bk2ndreq_but_nodessetup="Backup on Secondary is requested, but no destination has been set up"
f_bkonlypri_but_a_dessetup="03_bkonlypri_but_a_dessetup.txt"
v_bkonlypri_but_a_dessetup="Backup only requested on the primary, but a destination has been set up"
f_bk_cluster="04_bk_cluster.txt"
f_prim_cluster="05_prim_cluster.txt"
f_etc="06_etc.txt"
f_run_raw_snapmirror="00_run_raw_snapmirror_f.txt"

BLACK=`tput setaf 0`
RED=`tput setaf 1`
GREEN=`tput setaf 2`
YELLOW=`tput setaf 3`
BLUE=`tput setaf 4`
MAGENTA=`tput setaf 5`
CYAN=`tput setaf 6`
WHITE=`tput setaf 7`
BOLD=`tput bold`
RESET=`tput sgr0`

function f_usage()
{
  # Function: Print a help message.

  echo "${RED}Usage: $0 -h"
  echo "To clear log files: $0 -c"
  echo "=============================== ${RESET}"
  echo "copy all backup error from Checkmk to $f_new_checkmk_error_state"
  echo "in Checkmk: Monitor-> Problems -> Service problems"
  echo "Filter"
  echo "Service (regex)"
  echo "backup|vault"
  echo "host	service_description	svc_plugin_output"
}


function f_clear_files ()
{
  [ -f $f_bk2ndreq_but_nodessetup ] && rm $f_bk2ndreq_but_nodessetup
  [ -f $f_bkonlypri_but_a_dessetup ] && rm $f_bkonlypri_but_a_dessetup
  [ -f $f_bk_cluster ] && rm $f_bk_cluster
  [ -f $f_bk_cluster.tmp ] && rm $f_bk_cluster.tmp
  [ -f $f_prim_cluster ] && rm $f_prim_cluster
  [ -f $f_etc ] && rm $f_etc
  [ -f $f_run_raw_snapmirror ] && rm $f_run_raw_snapmirror
  echo > $f_new_checkmk_error_state
  rm -rf tmp/*
}


function f_init_files  ()
{
  cp -rf $f_new_checkmk_error_state bk/$f_new_checkmk_error_state$(date +"_%d-%m-%Y_%H:%M").bk
  sed -i 's/Snapvault//g' $f_new_checkmk_error_state
  grep "$v_bk2ndreq_but_nodessetup" $f_new_checkmk_error_state > $f_bk2ndreq_but_nodessetup
  sed -i "/$v_bk2ndreq_but_nodessetup/d" $f_new_checkmk_error_state
  grep "$v_bkonlypri_but_a_dessetup"  $f_new_checkmk_error_state > $f_bkonlypri_but_a_dessetup
  sed -i "/$v_bkonlypri_but_a_dessetup/d" $f_new_checkmk_error_state
  grep _vault $f_new_checkmk_error_state > $f_bk_cluster
  sed -i '/_vault/d' $f_new_checkmk_error_state
  grep .Vault.Backup $f_new_checkmk_error_state > $f_prim_cluster
  sed -i '/.Vault.Backup/d' $f_new_checkmk_error_state
  cp $f_new_checkmk_error_state $f_etc
}

function f_run_raw_snapmirror()
{
  cat $f_bk_cluster |awk '{print $1,$2}'>$f_bk_cluster.tmp
  while read -r cluster destpath; do
    echo "$cluster snapmirror show -destination-path  $destpath  -fields source-path,destination-path,policy,lag-time">> $f_run_raw_snapmirror
  done < $f_bk_cluster.tmp
  cat  $f_run_raw_snapmirror
}


case "${1}" in
  "")     echo "No option was specified. run $0 -h"; exit 1 ;;
  "-c")   f_clear_files ;;
  "-i")   f_init_files ;;
  "-r")   f_run_raw_snapmirror ;;
  "-h")   f_usage ;;
  *)      echo "Unknown shape '${1}'."; exit 1 ;;
esac

