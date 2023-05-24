#!/usr/bin/env bash
set -e

while getopts t:p: flag
do
    case "${flag}" in
        t) test=${OPTARG};;
        p) profile=${OPTARG};;
    esac
done

export FOUNDRY_PROFILE=$profile

if [ -z "$test" ]; then match="[contracts/test/*.t.sol]"; else match=$test; fi

forge test --match-test "$match" -vvv
