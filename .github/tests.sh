#!/bin/bash

command -v xargsb >& /dev/null || {
    xargsb() {
        local argcmd=$1
        [[ -x $1  ]] || argcmd=./xargsb
        $argcmd "$@"
    }
}

test_failed=0
function run_test() {
    #  - use an input string with space, tab, and newline delimiters to confirm various (sometimes unexpected)
    #    esoteric behavior differences of the original xargs depending on options and delimiter type.
    #  - use sort to ensure parallel ops diffs don't get random failures.

    echo "==== testing == xargs $*"
    diff \
        <(printf "1one 2two\n3x\n3y\n3z\n three \n\tfour\txfive\nxsix\t" | xargsb "$@" | sort) \
        <(printf "1one 2two\n3x\n3y\n3z\n three \n\tfour\txfive\nxsix\t" | env -i PATH="/usr/bin:/bin" xargs "$@" | sort) || {
            test_failed=1
            echo "==== FAILED  == xargs $*"
        }

    echo "==== testing == xargs -0 $*"
    diff \
        <(printf "1one\02two\03x\03y\03z\0 three \0\tfour\tzfive\0xsix\t" | xargsb -0 "$@" | sort) \
        <(printf "1one\02two\03x\03y\03z\0 three \0\tfour\tzfive\0xsix\t" | env -i PATH="/usr/bin:/bin" xargs -0 "$@" | sort) || {
            test_failed=1
            echo "==== FAILED  == xargs -0 $*"
        }

    return 0
}

function run_test_verbose() {
    # todo: add a test to confirm the verbose (-t) output matches xargs as well.
    return 0
}


run_test
run_test -n1
run_test -I SUBST -- echo "Item: SUBST"

run_test -P3 -n2
run_test -P3 -I SUBST -- echo "Item: SUBST"

exit $test_failed
