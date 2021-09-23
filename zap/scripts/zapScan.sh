#! /bin/sh

green=`tput setaf 2`
reset=`tput sgr0`

scanType=""
currentScanId=0
sleep=0
max_attempts=0

protocol=""
host=""

prjdir="$(cd "$(dirname "$0")"/../.. && pwd)"
self=$(basename $0)

usage() {
    cat << EOF

    Usage: $self -<option>
      -${green}pso${reset}: ${green}P${reset}assive ${green}S${reset}canner ${green}O${reset}n
      -${green}sp${reset}: ${green}SP${reset}ider scan | <shop>
      -${green}asp${reset}: ${green}A${reset}jax ${green}SP${reset}ider scan | <shop> [resultStart resultCount]
      -${green}as${reset}: ${green}A${reset}ctive ${green}S${reset}can | <shop>
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
      usage
      exit 1
    fi
  fi
fi

# switch on all passive scanner
allPassiveScannerOn() {
  scanInfo="$(curl -s 'http://localhost:8080/JSON/pscan/action/enableAllScanners')"

  passiveScannerOn="$(echo ${scanInfo} | cut -c12-$((${#scanInfo}-2)))"

  echo "#########################################"
  echo "All passive scanner switched on: ${passiveScannerOn}"
  echo "#########################################"
  echo ""
}

# reusable scan part for different taypes of scanning
scan() {
  attempt_counter=0
  statusResult=""

  while
    if [ ${attempt_counter} -eq ${max_attempts} ] ;then
      echo ""
      echo "Max attempts reached, exiting"
      echo "#########################################"
      echo ""

      # stop all running scans if it wasn't come to an end but exited
      curl -s 'http://localhost:8080/JSON/'${scanType}'/action/stopAllScans' > /dev/null
      curl -s 'http://localhost:8080/JSON/ajaxSpider/action/stop' > /dev/null

      exit 1
    fi

    if [ ${scanType} = "ajaxSpider" ] ;then
      statusResult="$(curl -s 'http://localhost:8080/JSON/ajaxSpider/view/status')"
      echo "Current scan status ($((${attempt_counter}+1))): $(echo ${statusResult} | cut -c12-$((${#statusResult}-2)))"
    else
      statusResult="$(curl -s 'http://localhost:8080/JSON/'${scanType}'/view/status/?scanId='${currentScanId})"
      echo "Current scan status ($((${attempt_counter}+1))): $(echo ${statusResult} | cut -c12-$((${#statusResult}-2)))%"
    fi

    attempt_counter=$(($attempt_counter+1))
    sleep ${sleep}

    [ "$statusResult" != "{\"status\":\"100\"}" ] && [ "$statusResult" != "{\"status\":\"stopped\"}" ]
  do true; done
}

# spider
spiderScan() {
  scanType="spider"
  sleep=2
  max_attempts=50

  # stop maybe still running privious scan, so there is no mess up
  curl -s 'http://localhost:8080/JSON/spider/action/stopAllScans' > /dev/null

  scanInfo="$(curl -s 'http://localhost:8080/JSON/spider/action/scan/?url='${protocol}'%3A%2F%2F'${host}'%2F&recurse=true&inScopeOnly=false&scanPolicyName=&method=&postData=&contextId=')"

  currentScanId=$(echo ${scanInfo} | cut -c10-$((${#scanInfo}-2)))

  echo "#########################################"
  echo "Started spider scan (ID: ${currentScanId})... "
  echo ""

  scan

  curl -s 'http://localhost:8080/xml/spider/view/results/?scanId='${currentScanId} > ${prjdir}/zap/results/spiderScan_${currentScanId}.xml

  echo ""
  echo "The scan results one can find here: ${prjdir}/zap/results/spiderScan_${currentScanId}.xml"
  echo ""
  echo "Spider scan finished"
  echo "#########################################"
  echo ""
}

# ajax spider
ajaxSpiderScan() {
  scanType="ajaxSpider"
  contextName=""
  sleep=5
  max_attempts=200

  if [ $# = 3 ] ;then
    resultStart=$2
    resultCount=$3
  else
    resultStart=0
    resultCount=100
  fi

  # stop maybe still running privious scan, so there is no mess up
  curl -s 'http://localhost:8080/JSON/ajaxSpider/action/stop' > /dev/null

  scanInfo="$(curl -s 'http://localhost:8080/JSON/ajaxSpider/action/scan/?url='${protocol}'%3A%2F%2F'${host}'%2F&inScope=false&contextName='${contextName}'&subtreeOnly=true')"

  echo "#########################################"
  echo "Started ajax spider scan... "
  echo ""

  scan

  curl -s 'http://localhost:8080/xml/ajaxSpider/view/results/?start='${resultStart}'&count='${resultCount} > ${prjdir}/zap/results/ajaxSpiderScan.xml
  echo ""
  echo "The scan results (from #'${resultStart}' to #'$((${resultStart}+${resultCount}))') one can find here: ${prjdir}/zap/results/ajaxSpiderScan.xml"
  echo ""
  echo "Ajax spider scan finished"
  echo "#########################################"
  echo ""
}

# active scan
activeScan() {
  scanType="ascan"
  sleep=5
  max_attempts=350

  # stop maybe still running privious scan, so there is no mess up
  curl -s 'http://localhost:8080/JSON/ascan/action/stopAllScans' > /dev/null

  scanInfo="$(curl -s 'http://localhost:8080/JSON/ascan/action/scan/?url='${protocol}'%3A%2F%2F'${host}'%2F&recurse=true&inScopeOnly=false&scanPolicyName=&method=&postData=&contextId=')"

  currentScanId=$(echo ${scanInfo} | cut -c10-$((${#scanInfo}-2)))

  echo "Started active scan (ID: ${currentScanId})... "
  echo ""

  scan

  curl -s 'http://localhost:8080/xml/ascan/view/alertsIds/?scanId='${currentScanId} > ${prjdir}/zap/results/activeScan_${currentScanId}.xml
  echo ""
  echo "The scan results one can find here: ${prjdir}/zap/results/activeScan_${currentScanId}.xml"
  echo ""
  echo "Active scan finished"
  echo "#########################################"
}

#####################################
# main
#####################################

while [ $# > 0  ]; do
  opt="$1"
  case "$opt" in
    -pso) shift && allPassiveScannerOn;;
    -sp) shift && spiderScan;;
    -asp) shift && ajaxSpiderScan "$@";;
    -as) shift && activeScan;;
    -h|*) usage ;;
  esac
done
