#!/bin/sh
# Execute cypress

set -e

stage1Value="http://juice:3000"
stage2Value="https://juice-shop.herokuapp.com"

prjdir="$(cd "$(dirname "$0")"/../.. && pwd)"
testDirectory="./cypress/integration/"
browser='none'
headless=" (headless)"

proxy_host=localhost

# for demarcation from system output
echo ""
echo "########################################################"
echo ""
echo " Setting ZAP as proxy..."
export HTTP_PROXY=http://${proxy_host}:8080
export HTTPS_PROXY=http://${proxy_host}:8080

# selects test mode, if not given as expected in $1
case "$1" in
  start)
    testMode='start'
    scenarioParam='--project '
    headless=''
    ;;
  test)
    # if it is sure one want to use test mode "test", selects browser
    testMode="test"
    echo "1) electron"
    echo "2) chrome"
    echo "3) firefox"
    echo "4) edge (only usable in native cypress, if edge is installed)"
    while [ ! "$browser" ] || [ "$browser" = none ]; do
      printf "Please enter your choice for BROWSER: "
      read -r optBrowser
      case $optBrowser in
        1)
          scenarioParam='--spec '
          browser='electron'
          echo "You chose choice '$optBrowser' which is '$browser'"
          echo "########################################################"
          echo ""
          ;;
        2)
          scenarioParam='--spec '
          browser='chrome'
          echo "You chose choice '$optBrowser' which is '$browser'"
          echo "########################################################"
          echo ""
          ;;
        3)
          scenarioParam='--spec '
          browser='firefox'
          echo "You chose choice '$optBrowser' which is '$browser'"
          echo "########################################################"
          echo ""
          ;;
        4)
          scenarioParam='--spec '
          browser='edge'
          echo "You chose choice '$optBrowser' which is '$browser'"
          echo "########################################################"
          echo ""
          ;;
        *) echo "Invalid option '$optBrowser'";;
      esac
    done
    ;;
  test_electron)
    testMode="test"
    scenarioParam='--spec '
    browser='electron'
    ;;
  test_chrome)
    testMode="test"
    scenarioParam='--spec '
    browser='chrome'
    ;;
  test_firefox)
    testMode="test"
    scenarioParam='--spec '
    browser='firefox'
    ;;
  test_edge)
    testMode="test"
    scenarioParam='--spec '
    browser='edge'
    ;;
  *)
    echo "Invalid input: $1" >&2
    echo "Usage: $0 start|test|test_electron|test_chrome|test_firefox|test_edge" >&2
    exit 1
    ;;
esac

# checks the given ($2) scenario for test execution
if [ "$2" = "all" ] ;then
  scenario="$2"
  scenarioBuild=""
else
  if ! echo "$2" | grep -Eq "\.spec\.js$"; then # "spec\.js" is a criteria to ensure the string seems to be correctly (file have to end with ".spec.js")
    scenario=""
    while ! echo "$scenario" | grep -Eq "\.spec\.js$" && [ "$scenario" != "all" ] ;do # "spec\.js" is a criteria to ensure the string seems to be correctly (file have to end with ".spec.js")
      printf "The scenario is not given (correctly)! Which SCENARIO should run: "
      read -r scenario
      if [ "$scenario" = "all" ] ;then
        scenarioBuild=""
      else
        scenarioBuild=$scenarioParam"${testDirectory}${scenario}"
      fi
    done
    echo "You want to run the following test(s): '$scenario'"
    echo "########################################################"
    echo ""
  else
    scenario="$2"
    scenarioBuild=$scenarioParam"${testDirectory}${scenario}"
  fi
fi

# selects stage (url) where the test should run, if not given as expected in $3
case $3 in
  local)
    stage="$stage1Value"
    ;;
  remote)
    stage="$stage2Value"
    ;;
  *)
    echo "1) local"
    echo "2) remote"
    while [ ! "$stage" ]; do
      printf "Please enter your choice for STAGE: "
      read -r opt3
      case $opt3 in
        1)
          stage="$stage1Value"
          echo "You chose choice '$opt3' which is '$stage'"
          echo "########################################################"
          echo ""
          ;;
        2)
          stage="$stage2Value"
          echo "You chose choice '$opt3' which is '$stage'"
          echo "########################################################"
          echo ""
          ;;
        *) echo "Invalid option '$opt3'";;
      esac
    done
  ;;
esac

# if the value in $4 is as expected, switchs on debug mode and (if needed, $5) debug filter
if [ "$4" = "debug" ] ;then
  debugMode="$4"
  debug='DEBUG=cypress:'

  if [ -n "$5" ] ;then
    debugFilter="$5"
    debugF="$5 "
  else
    debugFilter="noFilter"
    debugF="* "
  fi

# if no $4 is given, it sets values for debugMode="noDebug" and debugFilter="noFilter"
else
  debugMode="noDebug"
  debug=""
  debugFilter="noFilter"
  debugF=""
fi

browserParam=''
if [ "$browser" != none ]; then
  browserParam="--headless --browser $browser"
fi

echo ""
echo "########################################################"
echo "# Cypress tests will run with the following parameters:"
echo "# TestMode: '$testMode',"
echo "# Scenarios: '$scenario',"
echo "# Stage: '$stage',"
echo "# Browser: '$browser'$headless,"
echo "# DebugMode: '$debugMode',"
echo "# DebugFilter: '$debugFilter';"
echo "########################################################"

# the following deactivated code is for test purpose if something changes in
# this script and one want to know what string will be build to execute test
#echo ${debug}${debugF}\
#  npm run -- "${testMode}" \
#  "${browserParam}" \
#  --config "baseUrl=${stage}" \
#  "${scenarioBuild}"


# builds call for test execution
  eval ${debug}${debugF}\
    npm run -- "${testMode}" \
    "${browserParam}" \
    --config "baseUrl=${stage}" \
    "${scenarioBuild}"
