# Test suite

These tests use bash_unit to allow a clean visualisation of tests. 
This file describe some features used here. 

## `./config` file

This file allow the test suite to have some variables / command already set. You can customize.

## Setup/teardown

Like any regular test unit process, you can play command at initialisation of the test, and other at this end. It's used to generate fake directories or start docker commands. The teardown allow to clean directory/started container but if any fatal error happens (or `ctrl+c`), the tear down if not played. So you can have unwanted container started (you need to clean them manually, but it's not require to clean to re-execute because port/name/directory are random and uniq for each test suite).

## Pipe to `/dev/null`

Lot of command display result, error, warning. All are forward to /dev/null when it's not relevant (only the exit code is used `$?`). It's maybe usefull to provide a full log on these cases if it's possible to find a solution for that. 

## Uncommon command `tail -n +1`

When there is comparaison with grep, it's required to prefix by ` | tail -n +1`. It's do nothing at all (only display from the first line to the end) but avoid this warning "write /dev/stdout: broken pipe" if command make too long time for response (required for arm64 testing).

## `[[ $VARIANT != apache* ]]`

Some part of the test is not depend on variant of image. Per example here, apache. It's maybe useful to find another way to just ignore the test instead of `exit 0` the full file (bash unit do not manage that currently). 

