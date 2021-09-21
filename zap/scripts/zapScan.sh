#! /bin/sh

green=`tput setaf 2`
reset=`tput sgr0`

scanType=""
currentScanId=""
sleep=""
max_attempts=""

protocol=""
host=""

self=$(basename $0)

usage() {
    cat << EOF

    Usage: $self -<option> <shop>
      -${green}sp${reset}: ${green}SP${reset}ider scan
      -${green}asp${reset}: ${green}A${reset}jax ${green}SP${reset}ider scan
      -${green}as${reset}: ${green}A${reset}ctive ${green}S${reset}can
EOF
  exit 1
}

if [ "$2" = "local" ] ;then
  protocol="http"
  host="juice:3000"
else
  if [ "$2" = "remote" ] ;then
    protocol="https"
    host="juice-shop.herokuapp.com"
  else
    if [ "$1" != "-pso" ] ;then
      echo "#########################################"
      echo "Parameter for shop is missing!"
      echo "#########################################"
      exit 1
    fi
  fi
fi

# switch on all passive scanner
allPassiveScannerOn() {
scanInfo="$(curl -s 'http://localhost:8080/JSON/pscan/action/enableAllScanners')"

passiveScannerOn=$(echo ${scanInfo} | cut -c12-$((${#scanInfo}-2)))

echo "#########################################"
echo "All passive scanner switched on: ${passiveScannerOn}"
echo "#########################################"
echo ""
}

scan() {
  attempt_counter=0
  statusResult=""

  while
    if [ ${attempt_counter} -eq ${max_attempts} ]; then
      echo ""
      echo "Max attempts reached, scan exiting"
      echo "#########################################"
      echo ""
      exit 1
    fi

    if [ ${scanType} = "ajaxSpider" ]; then
      statusResult="$(curl -s 'http://localhost:8080/JSON/'${scanType}'/view/status')"
      echo "Current scan status ($((${attempt_counter}+1))): $(echo ${statusResult} | cut -c12-$((${#statusResult}-2)))"
    else
      statusResult="$(curl -s 'http://localhost:8080/JSON/'${scanType}'/view/status/?scanId='${currentScanId})"
      echo "Current scan status ($((${attempt_counter}+1))): $(echo ${statusResult} | cut -c12-$((${#statusResult}-2)))%"
    fi

    attempt_counter="$(($attempt_counter+1))"
    sleep ${sleep}

    [ "$statusResult" != "{\"status\":\"100\"}" ] || [ "$statusResult" != "{\"status\":\"stopped\"}" ]
  do true; done
}

# spider
spiderScan() {
scanType="spider"
sleep="2"
max_attempts=50

scanInfo="$(curl -s 'http://localhost:8080/JSON/spider/action/scan/?url='${protocol}'%3A%2F%2F'${host}'%2F&recurse=true&inScopeOnly=false&scanPolicyName=&method=&postData=&contextId=')"

currentScanId=$(echo ${scanInfo} | cut -c10-$((${#scanInfo}-2)))

echo "#########################################"
echo "Started spider scan (ID: ${currentScanId})... "
echo ""

scan

scanResults="$(curl -s 'http://localhost:8080/JSON/spider/view/results/?scanId='${currentScanId})"
echo ""
echo "Scan results: ${scanResults}"
echo ""
echo "Spider scan finished"
echo "#########################################"
echo ""
}

# ajax spider
ajaxSpiderScan() {
scanType="ajaxSpider"
contextName=""
sleep="5"
max_attempts=200

scanInfo="$(curl -s 'http://localhost:8080/JSON/ajaxSpider/action/scan/?url='${protocol}'%3A%2F%2F'${host}'%2F&inScope=false&contextName='${contextName}'&subtreeOnly=true')"

currentScanId=$(echo ${scanInfo} | cut -c10-$((${#scanInfo}-2)))

echo "#########################################"
echo "Started ajax spider scan... "
echo ""

scan

scanResults="$(curl -s 'http://localhost:8080/JSON/ajaxSpider/view/results/?start=0&count=100')"
echo ""
echo "Scan results: ${scanResults}"
echo ""
echo "Ajax spider scan finished"
echo "#########################################"
echo ""
}

# active scan
activeScan() {
scanType="ascan"
sleep="5"
max_attempts=200

scanInfo="$(curl -s 'http://localhost:8080/JSON/ascan/action/scan/?url='${protocol}'%3A%2F%2F'${host}'%2F&recurse=true&inScopeOnly=false&scanPolicyName=&method=&postData=&contextId=')"

currentScanId=$(echo ${scanInfo} | cut -c10-$((${#scanInfo}-2)))

if echo "$currentScanId" | grep -Eq "[a-zA-Z]"; then
  echo ""
  echo "ERROR: No scan (via cypress or spider) run before this active scan."
  return 0
else
  echo "Started active scan (ID: ${currentScanId})... "
  echo ""

  scan

  scanResults="$(curl -s 'http://localhost:8080/JSON/ascan/view/alertsIds/?scanId='${currentScanId})"
  echo ""
  echo "Scan results: ${scanResults}"
  echo ""
  echo "Active scan finished"
  echo "#########################################"
fi
}

#####################################
# main
#####################################

#if [ $# != 2 ]; then usage; fi

  opt="$1"
  case "$opt" in
    -pso) allPassiveScannerOn;;
    -sp) allPassiveScannerOn && spiderScan;;
    -asp) allPassiveScannerOn && ajaxSpiderScan;;
    -as) activeScan;;
    -h|*) usage ;;
  esac
