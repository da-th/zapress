#! /bin/sh

scanType=""
currentScanId=""
sleep=""

protocol=""
host=""

self=$(basename $0)

usage() {
    cat << EOF

    Usage: $self -<scan type> <shop>
      -s: spider scan
      -a: active scan
      -sa: spider scan and active scan one after another
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
  fi
fi

scan() {
  attempt_counter=0
  max_attempts=100
  statusResult=""

  while
    if [ ${attempt_counter} -eq ${max_attempts} ];then
      echo ""
      echo "Max attempts reached, scan exiting"
      echo "#########################################"
      echo ""
      exit 1
    fi

    statusResult="$(curl -s 'http://localhost:8080/JSON/'${scanType}'/view/status/?scanId='${currentScanId})"
    echo "Current scan status: $(echo ${statusResult} | cut -c12-$((${#statusResult}-2)))%"

    attempt_counter=$(($attempt_counter+1))
    sleep ${sleep}

    [ "$statusResult" != "{\"status\":\"100\"}" ]
  do true; done
}

# spider
spiderScan() {
scanType="spider"
sleep="2"

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

# active scan
activeScan() {
scanType="ascan"
sleep="5"

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

if [ $# != 2 ]; then usage; fi

  opt="$1"
  case "$opt" in
    -s) spiderScan;;
    -a) activeScan;;
    -sa) spiderScan && activeScan;;
    -h|*) usage ;;
  esac
