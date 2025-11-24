#!/usr/bin/env python3
# pip install -U persiantools tabulate colorama

from datetime import datetime
from zoneinfo import ZoneInfo
from persiantools.jdatetime import JalaliDateTime
import calendar
from tabulate import tabulate
from colorama import Fore, Style

# Persian names
PERSIAN_WEEKDAYS = [
    "دوشنبه", "سه‌شنبه", "چهارشنبه", "پنج‌شنبه",
    "جمعه", "شنبه", "یک‌شنبه",
]

PERSIAN_MONTHS = [
    "فروردین", "اردیبهشت", "خرداد",
    "تیر", "مرداد", "شهریور",
    "مهر", "آبان", "آذر",
    "دی", "بهمن", "اسفند"
]

GREGORIAN_SEASONS = ["Winter", "Spring", "Summer", "Autumn"]
PERSIAN_SEASONS = [
    "Zemestān - زمستان",
    "Bahār - بهار",
    "Tābestān - تابستان",
    "Pāyiz - پاییز"
]

def get_persian_season(j_month):
    if 1 <= j_month <= 3:
        return PERSIAN_SEASONS[1]
    elif 4 <= j_month <= 6:
        return PERSIAN_SEASONS[2]
    elif 7 <= j_month <= 9:
        return PERSIAN_SEASONS[3]
    else:
        return PERSIAN_SEASONS[0]

def get_gregorian_season(month):
    if month in [12, 1, 2]:
        return GREGORIAN_SEASONS[0]
    elif month in [3, 4, 5]:
        return GREGORIAN_SEASONS[1]
    elif month in [6, 7, 8]:
        return GREGORIAN_SEASONS[2]
    else:
        return GREGORIAN_SEASONS[3]

def main():
    # Berlin time
    berlin_tz = ZoneInfo("Europe/Berlin")
    now_berlin = datetime.now().astimezone(berlin_tz)
    weekday_en = calendar.day_name[now_berlin.weekday()]
    month_en = calendar.month_name[now_berlin.month]
    gregorian_season = get_gregorian_season(now_berlin.month)

    # Tehran time
    tehran_tz = ZoneInfo("Asia/Tehran")
    now_tehran = datetime.now().astimezone(tehran_tz)
    jalali = JalaliDateTime.to_jalali(now_tehran)
    j_weekday = PERSIAN_WEEKDAYS[now_tehran.weekday()]
    j_month_name = PERSIAN_MONTHS[jalali.month - 1]
    persian_season = get_persian_season(jalali.month)

    # Prepare table data
    table = [
        [Fore.MAGENTA + "Date" + Style.RESET_ALL,
         f"{Fore.CYAN}{now_berlin.strftime('%Y-%m-%d')}, {weekday_en}, {now_berlin.day} {month_en} {now_berlin.year}{Style.RESET_ALL}",
         f"{Fore.GREEN}{jalali.year}-{jalali.month:02d}-{jalali.day:02d}, {j_weekday}، {jalali.day} {j_month_name} {jalali.year}{Style.RESET_ALL}"],
        [Fore.MAGENTA + "Time" + Style.RESET_ALL,
         f"{Fore.CYAN}{now_berlin.strftime('%H:%M:%S %Z%z')}{Style.RESET_ALL}",
         f"{Fore.GREEN}{jalali.hour:02d}:{jalali.minute:02d}:{jalali.second:02d}{Style.RESET_ALL}"],
        [Fore.MAGENTA + "Season" + Style.RESET_ALL,
         f"{Fore.CYAN}{gregorian_season}{Style.RESET_ALL}",
         f"{Fore.GREEN}{persian_season}{Style.RESET_ALL}"]
    ]

    # Print table
    print(tabulate(table, headers=[Fore.YELLOW + "Field" + Style.RESET_ALL,
                                   Fore.YELLOW + "Gregorian (Berlin)" + Style.RESET_ALL,
                                   Fore.YELLOW + "Jalali (Tehran)" + Style.RESET_ALL],
                   tablefmt="fancy_grid"))

if __name__ == "__main__":
    main()
