#!/bin/env bash

function assert_exists() {
    local val="$1"
    local message="$2"
    if [ -z "$val" ]; then
        if [ -n "$message" ]; then
            echo "$message"
        else
            echo "$val does not exist"
        fi
        exit 1
    fi
}