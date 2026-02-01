#!/usr/bin/env bash

function get_date() {
  local -n __d__="$1"
  local year month month_name day hours_24 minutes seconds

  year="$(date -u +%Y)"
  month="$(date -u +%-m)"
  month_name="$(date -u +%B)"
  day="$(date -u +%-d)"
  hours_24="$(date -u +%-H)"
  minutes="$(date -u +%M)"
  seconds="$(date -u +%S)"

  __d__=(
    [year]="$year"
    [month]="$month_name"
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
  elif ((day % 10 == 3)); then
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
