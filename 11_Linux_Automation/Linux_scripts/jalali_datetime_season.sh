#!/usr/bin/env bash

# Colors
MAGENTA="\033[35m"
CYAN="\033[36m"
GREEN="\033[32m"
YELLOW="\033[33m"
RESET="\033[0m"

PERSIAN_WEEKDAYS=(
  "دوشنبه" "سه‌شنبه" "چهارشنبه" "پنج‌شنبه"
  "جمعه" "شنبه" "یک‌شنبه"
)

PERSIAN_MONTHS=(
  "فروردین" "اردیبهشت" "خرداد"
  "تیر" "مرداد" "شهریور"
  "مهر" "آبان" "آذر"
  "دی" "بهمن" "اسفند"
)

get_gregorian_season() {
  local m=$1
  if [[ $m -eq 12 || $m -le 2 ]]; then echo "Winter"
  elif [[ $m -le 5 ]]; then echo "Spring"
  elif [[ $m -le 8 ]]; then echo "Summer"
  else echo "Autumn"
  fi
}

get_persian_season() {
  local jm=$1
  if (( jm>=1 && jm<=3 )); then echo "Bahār - بهار"
  elif (( jm<=6 )); then echo "Tābestān - تابستان"
  elif (( jm<=9 )); then echo "Pāyiz - پاییز"
  else echo "Zemestān - زمستان"
  fi
}

# Berlin time
B_DATE=$(TZ=Europe/Berlin date "+%Y-%m-%d")
B_WEEKDAY=$(TZ=Europe/Berlin date "+%A")
B_DAY=$(TZ=Europe/Berlin date "+%d")
B_MONTH_NAME=$(TZ=Europe/Berlin date "+%B")
B_YEAR=$(TZ=Europe/Berlin date "+%Y")
B_TIME=$(TZ=Europe/Berlin date "+%H:%M:%S %Z%z")
B_MONTH_NUM=$(TZ=Europe/Berlin date "+%m")

G_SEASON=$(get_gregorian_season $((10#$B_MONTH_NUM)))

# Tehran time
T_TIME=$(TZ=Asia/Tehran date "+%H:%M:%S")
WD=$(TZ=Asia/Tehran date +%u)
P_WEEKDAY=${PERSIAN_WEEKDAYS[$((WD-1))]}

# Jalali date via Python (accurate)
JALALI=$(python3 -c '
from datetime import datetime
from zoneinfo import ZoneInfo
from persiantools.jdatetime import JalaliDateTime
now=datetime.now(ZoneInfo("Asia/Tehran"))
j=JalaliDateTime.to_jalali(now)
print(j.year, f"{j.month:02d}", f"{j.day:02d}")
')

read JY JM JD <<< "$JALALI"

PMONTH=${PERSIAN_MONTHS[$((10#$JM-1))]}
P_SEASON=$(get_persian_season $((10#$JM)))

# Strings
G_DATE_STR="${B_DATE}, ${B_WEEKDAY}, ${B_DAY} ${B_MONTH_NAME} ${B_YEAR}"
J_DATE_STR="${JY}-${JM}-${JD}, ${P_WEEKDAY}، ${JD} ${PMONTH} ${JY}"

# Table
printf "╒═════════╤════════════════════════════════════════╤════════════════════════════════════╕\n"
printf "│ ${YELLOW}Field${RESET}   │ ${YELLOW}Gregorian (Berlin)${RESET}                     │ ${YELLOW}Jalali (Tehran)${RESET}                    │\n"
printf "╞═════════╪════════════════════════════════════════╪════════════════════════════════════╡\n"

printf "│ ${MAGENTA}Date${RESET}    │ ${CYAN}%-38s${RESET} │ ${GREEN}%-34s${RESET} │\n" "$G_DATE_STR" "$J_DATE_STR"
printf "├─────────┼────────────────────────────────────────┼────────────────────────────────────┤\n"

printf "│ ${MAGENTA}Time${RESET}    │ ${CYAN}%-38s${RESET} │ ${GREEN}%-34s${RESET} │\n" "$B_TIME" "$T_TIME"
printf "├─────────┼────────────────────────────────────────┼────────────────────────────────────┤\n"

printf "│ ${MAGENTA}Season${RESET}  │ ${CYAN}%-38s${RESET} │ ${GREEN}%-34s${RESET} │\n" "$G_SEASON" "$P_SEASON"

printf "╘═════════╧════════════════════════════════════════╧════════════════════════════════════╛\n"


