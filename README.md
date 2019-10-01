# bashUnitTestLib
A lite unit test framework for bash using a bash script, not an exectuable

The purpose of this testing framework is to run inside bash, at the expense of fancy features.  Instead, you can write bash test cases **without** the need for **installing an executable**. This has the distinct advantage of running unit tests where they are deployed **without requiring** a software bash unit tester installed.  In my experience, that's pretty much everywhere you want to run unit tests when delivering code to new machines.

Another advantage is simplicity, ease of use, and speed.  It is not a foreign concept to a bash developer to write everything in a linear manner; so we don't necessarily need high powered syntax for unit tests, which requires an independent interpretter.

You can do most of the things frameworks like bats (https://github.com/ztombol/bats-docs) and bash_unit (https://github.com/pgrange/bash_unit) provide.

* Execute tests in their **own environment**: use a script called to process tests independently
* **Setup** and **teardown** : you simply call the functions as appropriate before and after in the script.
* **assertions** : you can use the provided functions or write your own following the template
* control the **level of verbosity**: report only errors, only final tally, etc.
* you can do "tests within tests": multiple assertions per test that count as 1 success or failure
* use in **any Docker**: it's a bash script

bashUnitTestLib does not allow mocking and is not TAP compliant.
TAP compliant output could be added as a feature in the future.

## How it works

This is not TAP compliant.  However, while the syntax does not mimick (more complicated) TAP, you will see that bashUnitTestLib mimicks such frameworks in flow. Instead of using functions and code blocks like junit, we use the function "testBegin."  If you want multiple assertions per test, you can optionally use "subtestBlockBegin" and "subtestBlockEnd".

If you want to setup or teardown, simply do so.

bashUnitTestLib tracks successes and failures by looking at exit codes, in customary bash fashion.  (Note that some operators like ++ don't use exit codes this way.)
Any failures cause the script to return exit code 1.  This "rolls up" the results.  Stdout can captures the specifics.

## Using bashUnitTestLib

You write a script that runs a battery of unit tests.  You can additionally have a master script that calls multiple test scripts as a layer of organization.  (As you would using junit).  It may seem onerous to isolate each test environment in a separate file; I can say (1) welcome to bash and (2) you might want a fancier test framework.

bashUnitTestLib works by capturing the return code of the last command.  This is simplistic, but effective.  You can use or write assertions to eliminate the testProcessResult command called on a second line, which some might find cluttery and offensive.

~~~bash
. bashUnitTest.lib.sh

# INITIAL setup -- just plop it into the script
SCRIPT_DIR="$(realpath $(dirname "$0"))"

testsInit 1

testBegin "testSubtraction 1" "Example demonstrating the use of exit codes"
[[ $((5 - 2)) -eq 3 ]]
testProcessResult $?

testBegin "testSubtraction 2" "Example demonstrating the use of assertions"
assertEquals $((5 - 2)) 3


testBegin "testCertificates" "Example using setup and teardown"

# setup example
local mnt=$(mktemp -d tmp.XXXXXX)
mount "my.iso" "$mnt"

for cert in *.pem; do
  assertCertHasCountry "$cert" "US"
done

# teardown example
umount "$mnt"
rm -rf "$mnt"

# ... do more tests

testFinalResults    # optional text summary of results
exit $(testExitCode)
~~~

## Versioning

0.5 First commit: porting from another project.  In progress of implementing some improvements things.
