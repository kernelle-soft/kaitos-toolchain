#!/usr/bin/env bash

declare __get_date__months=(
  "January"
  "February"
  "March"
  "April"
  "May"
  "June"
  "July"
  "August"
  "September"
  "October"
  "November"
  "December"
)

function get_date() {
  local str_date
  local -n _date="$1"
  local year month day hours_24 hours_12 ampm minutes seconds
  local day_suffix

  str_date="$(date -u +"%Y-%-m-%-dT%-H:%M:%SZ")"

  year="${str_date%%-*}"; str_date="${str_date#*-}"
  month="${str_date%%-*}"; str_date="${str_date#*-}"
  day="${str_date%%T*}"; str_date="${str_date#*T}"
  hours_24="${str_date%%:*}"; str_date="${str_date#*:}"
  minutes="${str_date%%:*}"; str_date="${str_date#*:}"
  seconds="${str_date%%Z*}";

  _date=(
    [year]="$year"
    [month]="${__get_date__months[$((month - 1))]}"
    [day]="$day"
    [day_suffix]="$(__get_date__day_suffix "$day")"
    [hours_24]="$hours_24"
    [hours_12]="$(__get_date__hours_12 "$hours_24")"
    [ampm]="$(__get_date__ampm "$hours_24")"
    [minutes]="$minutes"
    [seconds]="$seconds"
    [timezone]="UTC"
  )
}

function __get_date__day_suffix() {
  local day="${1}" suffix
  if [[ $day -ge 11 && $day -le 13 ]]; then
    suffix="th"
  elif ((day % 10 == 1)); then
    suffix="st"
  elif ((day % 10 == 2)); then
    suffix="nd"
  elif ((day%10 == 3)); then
    suffix="rd"
  else
    suffix="th"
  fi

  echo "$suffix"
}

function __get_date__ampm() {
  local hours_24="$1"
  if ((hours_24 < 12)); then
    echo "AM"
  else
    echo "PM"
  fi
}

function __get_date__hours_12() {
  local hours_24="$1" hours_12
  hours_12="$((hours_24 % 12))"
  if ((hours_12 == 0)); then
    hours_12=12
  fi

  echo "$hours_12"
}
