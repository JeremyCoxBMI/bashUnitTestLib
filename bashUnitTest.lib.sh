#!/usr/bin/env bash

# Unit Tests Library for bash
# - run test blocks
#   - run subtesting blocks as one unit test
# - count successes
# - retain pass/fail status of a test after execution
#
# See README for more information

set -euo pipefail

# ################################################################################
# Running tests script
#   Typically, call each function once per script
# ################################################################################

# initialize testing counts
# Called once per paired final call `testFinalResults` and optionally `exit $(testExitCode)`
# $1    squelch output when (1) successful test result or (2) status messages: 1 (true) or 0 (false)
testsInit() {
    # globals tracking test results
    COUNT_SUCCESS=0
    COUNT_TEST=0
    SUBTEST_COUNT_SUCCESS=0
    SUBTEST_COUNT_TEST=0
    [[ -z "$1" ]] && SQUELCH=0 || SQUELCH=$1
    IN_SUBTEST=0
    FAILED=0
    EXIT_CODE=0
}

# heading to use when beginning a unit test block; establishes values for output statements
# can use once or multiple times to create new test blocks with new headings
# note that a unit test block typically contains multiple unit tests
#    analogous to a .java file containing multiple test functions
# $1    test name
# $2    test description
testBegin() {
    TEST_NAME="$1"
    TEST_DESC="$2"
    if [[ "$SQUELCH" -eq 0 ]]; then
        echo " * * * * $TEST_NAME: $TEST_DESC * * * *"
        echo ""
    fi
}

# Called at the end of a testing block started by testsInit
# Displays results neatly (optional)
testFinalResults(){

    local  leftPad=$((12 - ${#COUNT_SUCCESS}))
    local rightPad=$((12 - ${#COUNT_TEST}))
           leftPad="$(head -c $leftPad  < /dev/zero | tr '\0' ' ')"
          rightPad="$(head -c $rightPad < /dev/zero | tr '\0' ' ')"


    echo ""
    echo "|---------------------------------------------|"
    if [[ $COUNT_SUCCESS -eq $COUNT_TEST ]]; then
        echo "|          ### RESULT ###      PASSED         |"
    else
        echo "|          ### RESULT ###   >> FAILED <<      |"
    fi
    echo "|$leftPad$COUNT_SUCCESS tests passed out of $COUNT_TEST$rightPad|"
    echo "|---------------------------------------------|"
    echo ""
}

# ################################################################################
# Running a test block; executing a unit test
#   test block is an organizational grouping of tests
# ################################################################################

# label a testing block; aesthetics/indentations match testFinalResults
# $1    the message to display
testBlockLabel() {
    if [[ "$SQUELCH" -eq 0 ]]; then
        local width=$((${#1} + 6))
        echo '    |'"$(head -c $width < /dev/zero | tr '\0' '-')"'|'
        echo "    | # $1 # |"
        echo '    |'"$(head -c $width < /dev/zero | tr '\0' '-')"'|'
        echo ""
    fi
}

# after running a unit test (or subtest), call this to record result
# output and tabulate test result
#     analogous to the java unit test framework recording a function's unit test result
# $1    success (0) or failure (any int)
# $2    success message
# $3    failure message
testProcessResult(){
    assertExitCodeZero "$@"
}

# add a message to console, typically status update when doing multiple steps that aren't assertions/unit tests
# such as processing a large file
# This is a comment purely for user's benefit.  Can be squelched.
# $1    message to display
testActivityMessage() {
    if [[ "$SQUELCH" -eq 0 ]]; then
        echo "    >>> $1"
        echo ""
    fi
}

# ################################################################################
# Running a subtest block
#   subtest block is multiple assertions as part of a single unit test
#   in other words, the subtests count towards the total as 1 unit test
#   you would do this, for example, if you had three assertions for one test
#     subtestBlock is analogous to a single test function within .java containing multiple assertions
# ################################################################################


# a subtestBlock allows you to do multiple tests, but count as 1 towards the total number of tests
# $1  description of the subtest block
subtestBlockBegin(){
    [[ IN_SUBTEST -eq 1 ]] && echo 'You are trying to start a subtest block inside a subtest block' \
             && echo "FOR $TEST_NAME: $TEST_DESC: $1" && exit 1

    echo "     * * * * Beginning a subtest block $1: multiple assertions counting as one test * * * *"
    echo "               inside $TEST_NAME :: $TEST_DESC "
    echo ""

    SUBTEST_NAME="$1"
    UNIT_TEST_NAME=
    IN_SUBTEST=1
    SUBTEST_COUNT_SUCCESS=0
    SUBTEST_COUNT_TEST=0
}

# end the subtest and tabulate results as a single unit test
# $1 (optional) squelch output 0 = no, 1 = yes, DEFAULT: only if failed
subtestBlockEnd(){
    IN_SUBTEST=0
    local squelch=${1:=2}
    [[ "$SUBTEST_COUNT_TEST" -eq "$SUBTEST_COUNT_SUCCESS" ]]
    local result=$?
    testProcessResult $result

    [[ $squelch -eq 1 ]]                  && subtestBlockMessage
    [[ $squelch -eq 2 && $result -eq 1 ]] && subtestBlockMessage
}

# helper function, do not use in your script
subtestBlockMessage(){
#   local   leftPad=$((12 - ${#SUBTEST_COUNT_SUCCESS}))
#   local  rightPad=$((12 - ${#SUBTEST_COUNT_TEST}))
#   local middlePad=${#SUBTEST_NAME}
#           leftPad="$(head -c $leftPad   < /dev/zero | tr '\0' ' ')"
#          rightPad="$(head -c $rightPad  < /dev/zero | tr '\0' ' ')"
#         middlePad="$(head -c $middlePad < /dev/zero | tr '\0' ' ')"
#
#    echo ""
#    echo "        |--------------SUBTEST: $SUBTEST_NAME----------------------|"
#    if [[ $SUBTEST_COUNT_SUCCESS -eq $SUBTEST_COUNT_TEST ]]; then
#        echo "        |          ### RESULT ###      PASSED         $middlePad|"
#    else
#        echo "        |          ### RESULT ###   >> FAILED <<      |"
#    fi
#    echo "        |$leftPad$SUBTEST_COUNT_SUCCESS tests passed out of $SUBTEST_COUNT_TEST$middlePad$rightPad|"
#    echo "        |--------------$SUBTEST_NAME-------------------------------|"
#    echo ""

    echo ""
    printBoxLine 8 15 65 '-' "SUBTEST: $SUBTEST_NAME"
    if [[ $SUBTEST_COUNT_SUCCESS -eq $SUBTEST_COUNT_TEST ]]; then
        printBoxLine 8 15 65 '__' "### RESULT ###      PASSED"
    else
        printBoxLine 8 15 65 '__' "### RESULT ###   >> FAILED <<"
    fi
    printBoxLine 8 10 65 '__' "$SUBTEST_COUNT_SUCCESS tests passed out of $SUBTEST_COUNT_TEST"
    printBoxLine 8 19 65 '__' "END: $SUBTEST_NAME"
    echo ""

    SUBTEST_COUNT_SUCCESS=0
    SUBTEST_COUNT_TEST=0
}

# $1 character to repeat  (only first char is used)  use "__" for space
# $2 length (integer)
# return string of repeating characters
repeatChar() {
    if [[ $1 == "__" ]]; then
        local spaces=$(head -c "$2"   < /dev/zero | tr '\0' ' ')
        printf "$spaces"
    else
        echo $(head -c "$2"   < /dev/zero | tr '\0' "$1")
    fi
}

# $1 number of spaces to print
#printSpaces() {
#    local spaces=$(head -c "$1"   < /dev/zero | tr '\0' ' ')
#    printf "$spaces"
#}

# $ text to display
# $1 indent
# $2 start column (column in string to start the provided string)
# $3 width
# $4 character to use as fill, use '__' to represent a space
# $5 message for the line
printBoxLine(){
    #note that "|" "|" start and end caps add 2 characters
    echo "$(repeatChar '__' $(($1)))|$(repeatChar $4 $(($2-3))) $5 $(repeatChar $4 $(( $width - $2 - ${#5} - 1 )) )|"
}

# Give a name before each specific subtest; i.e. before each testProcessResult
# $1 text to display when reporting success/failures
subtestName(){
    UNIT_TEST_NAME="$1"
}

# ################################################################################
# Assertions
#   Used within subtest block, each assertion counts as a subtest
#   Outside a subtest block, each assertion counts as a unit test (analgous to java unit test "test..." function)
# ################################################################################

# output and tabulate test result
# $1    success (0) or failure (any int)
# $2    success message
# $3    failure message
assertExitCodeZero(){
    [[ IN_SUBTEST -eq 1 ]] && pad='          ' || pad='    '
    if [[ "$1" -eq 0 ]]; then
       if [[ "$SQUELCH" -eq 0 ]]; then
           [[ IN_SUBTEST -eq 1 ]]                                           && \
              echo "$pad--   --> $TEST_NAME :: (subtest) $UNIT_TEST_NAME"   || \
              echo "$pad         $TEST_NAME :: $TEST_DESC "
           echo "$pad              PASSED   $2"
           echo ""
       fi
       FAILED=0
       [[ IN_SUBTEST -eq 1 ]] && SUBTEST_COUNT_SUCCESS=$((SUBTEST_COUNT_SUCCESS + 1)) || COUNT_SUCCESS=$((COUNT_SUCCESS + 1))
    else
       [[ IN_SUBTEST -eq 1 ]]                                               && \
          echo "$pad--   --> $TEST_NAME :: (subtest) $UNIT_TEST_NAME"       || \
          echo "$pad--   --> $TEST_NAME :: $TEST_DESC"
       echo "$pad              FAILED   $3"
       echo ""
       FAILED=1
       EXIT_CODE=1   #all tests since testsInit collectively fail
    fi
    [[ IN_SUBTEST -eq 1 ]] && SUBTEST_COUNT_TEST=$((SUBTEST_COUNT_TEST + 1)) || COUNT_TEST=$((COUNT_TEST + 1))
}

# asserts the value is within the range, inclusive
# $1 lower limit
# $2 upper limit
# $3 test value
assertInRangeInclusive() {
    assertExitCodeZero $(inRangeInclusive $1 $2 $3)
}


# ################################################################################
# Getting overall result of unit tests
#   EXAMPLE:  at end, `exit $(testExitCode)`
# ################################################################################

# Called at the end of a testing block started by testInit
testExitCode() {
    if [[ "$COUNT_SUCCESS" -ne "$COUNT_TEST" ]]; then echo 1; else echo 0; fi
}

didAllTestsPass() {
    [[ $EXIT_CODE -eq 0 ]]
}

didLastTestPass() {
    [[ $FAILED -eq 0 ]]
}


# ########################################
# Helper functions to testing core
# ########################################

# tests if value is within the range, inclusive
# $1 lower limit
# $2 upper limit
# $3 test value
inRangeInclusive() {
    if [[ "$1" -le "$3" && "$3" -le "$2" ]]; then echo 0; else echo 1; fi
}
