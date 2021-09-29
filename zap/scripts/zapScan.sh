#! /bin/sh

green=`tput setaf 2`
reset=`tput sgr0`

scanType=""
currentScanId=0
sleep=0
max_attempts=0

protocol=""
host=""
file=""

prjdir="$(cd "$(dirname "$0")"/../.. && pwd)"
self=$(basename $0)

usage() {
    cat << EOF

    Usage: $self -<option>
      -${green}eps${reset}: ${green}E${reset}nable ${green}P${reset}assive ${green}S${reset}canner according config in file
            (./zap/configs/defaultPassiveScannerEnable) [alter file]
      -${green}eaps${reset}: ${green}E${reset}nable ${green}A${reset}ll ${green}P${reset}assive ${green}S${reset}canner
      -${green}daps${reset}: ${green}D${reset}isable ${green}A${reset}ll ${green}P${reset}assive ${green}S${reset}canner
      -${green}sp${reset}: ${green}SP${reset}ider scan | <shop>
      -${green}asp${reset}: ${green}A${reset}jax ${green}SP${reset}ider scan | <shop> [resultStart resultCount]
      -${green}eas${reset}: ${green}E${reset}nable ${green}A${reset}ctive ${green}S${reset}canner according config in file
            (./zap/configs/defaultActiveScannerEnable) [alter file]
      -${green}eaas${reset}: ${green}E${reset}nable ${green}A${reset}ll ${green}A${reset}ctive ${green}S${reset}canner
      -${green}daas${reset}: ${green}D${reset}isable ${green}A${reset}ll ${green}A${reset}ctive ${green}S${reset}canner
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
    if [ "$1" = "-eps" ] || [ "$1" = "-eas" ] && [ "$2" != "" ] ;then
    file="$2"
    else
      if [ "$1" != "-eaps" ] && [ "$1" != "-daps" ] && [ "$1" != "-eps" ] && [ "$1" != "-eas" ] ;then
        echo "###################################################"
        echo "Parameter for shop ('local'/'remote') is missing!"
        echo "###################################################"
        echo ""
        usage
        exit 1
      fi
    fi
  fi
fi

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
      usage

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

#####################################
# passive scan
#####################################

# show enabled passive scanner
showEnabledPassiveScanner() {
  scanInfo="$(curl -s 'http://localhost:8080/JSON/pscan/view/scanners')"

  enabledPassiveScanner="$(echo ${scanInfo} | cut -c12-$((${#scanInfo}-2)))"

  echo ""
  echo "#########################################"
  echo "Enabled passive scanner: ${enabledPassiveScanner}"
  echo "#########################################"
  echo ""
}

# enable passive scanner
enablePassiveScanner() {
  if [ "$file" = "" ] ;then
    read scannerIds < ${prjdir}/zap/configs/defaultPassiveScannerEnable
  else
    read scannerIds < ${prjdir}/zap/configs/${file}
  fi
  cleanedScannerIds="$(echo $(echo ${scannerIds} |  sed -e 's/,/%2C+/g') |  sed -e 's/ //g')"

  scanInfo="$(curl -s 'http://localhost:8080/JSON/pscan/action/enableScanners/?ids='${cleanedScannerIds})"

  enabledPassiveScanner="$(echo ${scanInfo} | cut -c12-$((${#scanInfo}-2)))"

  echo ""
  echo "#########################################"
  echo "Enable passive scanner (IDs): ${scannerIds}"
  echo "Status: ${enabledPassiveScanner}"
  echo "#########################################"
  echo ""
}

# enable all passive scanner
enableAllPassiveScanner() {
  scanInfo="$(curl -s 'http://localhost:8080/JSON/pscan/action/enableAllScanners')"

  passiveScannerOn="$(echo ${scanInfo} | cut -c12-$((${#scanInfo}-2)))"

  echo ""
  echo "#########################################"
  echo "Enable all passive scanner: ${passiveScannerOn}"
  echo "#########################################"
  echo ""
}

# disable all passive scanner
disableAllPassiveScanner() {
  scanInfo="$(curl -s 'http://localhost:8080/JSON/pscan/action/disableAllScanners')"

  passiveScannerOff="$(echo ${scanInfo} | cut -c12-$((${#scanInfo}-2)))"

  echo ""
  echo "#########################################"
  echo "Disable all passive scanner: ${passiveScannerOff}"
  echo "#########################################"
  echo ""
}

# spider
spiderScan() {
  scanType="spider"
  sleep=2
  max_attempts=5

  # stop maybe still running privious scan, so there is no mess up
  curl -s 'http://localhost:8080/JSON/spider/action/stopAllScans' > /dev/null

  scanInfo="$(curl -s 'http://localhost:8080/JSON/spider/action/scan/?url='${protocol}'%3A%2F%2F'${host}'%2F&recurse=true&inScopeOnly=false&scanPolicyName=&method=&postData=&contextId=')"

  currentScanId=$(echo ${scanInfo} | cut -c10-$((${#scanInfo}-2)))

  echo ""
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

  echo ""
  echo "#########################################"
  echo "Started ajax spider scan... "
  echo ""

  scan

  curl -s 'http://localhost:8080/xml/ajaxSpider/view/results/?start='${resultStart}'&count='${resultCount} > ${prjdir}/zap/results/ajaxSpiderScan.xml
  echo ""
  echo "The scan results (from #'${resultStart}' to #'$((${resultStart}+${resultCount}))') one can find here:"
  echo "${prjdir}/zap/results/ajaxSpiderScan.xml"
  echo ""
  echo "Ajax spider scan finished"
  echo "#########################################"
  echo ""
}

#####################################
# active scan
#####################################

# enable active scanner
enableActiveScanner() {
  if [ "$file" = "" ] ;then
    read scannerIds < ${prjdir}/zap/configs/defaultActiveScannerEnable
  else
    read scannerIds < ${prjdir}/zap/configs/${file}
  fi
  cleanedScannerIds="$(echo $(echo ${scannerIds} |  sed -e 's/,/%2C+/g') |  sed -e 's/ //g')"

  scanInfo="$(curl -s 'http://localhost:8080/JSON/ascan/action/enableScanners/?ids='${cleanedScannerIds}'&scanPolicyName=')"

  enabledActiveScanner="$(echo ${scanInfo} | cut -c12-$((${#scanInfo}-2)))"

  echo ""
  echo "#########################################"
  echo "Enable active scanner (IDs): ${scannerIds}"
  echo "Status: ${enabledActiveScanner}"
  echo "#########################################"
  echo ""
}

# enable all active scanner
enableAllActiveScanner() {
  scanInfo="$(curl -s 'http://localhost:8080/JSON/ascan/action/enableAllScanners/?scanPolicyName=')"

  activeScannerOn="$(echo ${scanInfo} | cut -c12-$((${#scanInfo}-2)))"

  echo ""
  echo "#########################################"
  echo "Enable all active scanner: ${activeScannerOn}"
  echo "#########################################"
  echo ""
}

# disable all active scanner
disableAllActiveScanner() {
  scanInfo="$(curl -s 'http://localhost:8080/JSON/ascan/action/disableAllScanners/?scanPolicyName=')"

  activeScannerOff="$(echo ${scanInfo} | cut -c12-$((${#scanInfo}-2)))"

  echo ""
  echo "#########################################"
  echo "Disable all active scanner: ${activeScannerOff}"
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

  echo ""
  echo "#########################################"
  echo "Started active scan (ID: ${currentScanId})... "
  echo ""

  scan

  curl -s 'http://localhost:8080/xml/ascan/view/alertsIds/?scanId='${currentScanId} > ${prjdir}/zap/results/activeScan_${currentScanId}.xml
  echo ""
  echo "The scan results one can find here:"
  echo "${prjdir}/zap/results/activeScan_${currentScanId}.xml"
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
    -seps) shift && showEnabledPassiveScanner;;
    -eps) shift && disableAllPassiveScanner && enablePassiveScanner;;
    -eaps) shift && enableAllPassiveScanner;;
    -daps) shift && disableAllPassiveScanner;;
    -sp) shift && spiderScan;;
    -asp) shift && ajaxSpiderScan "$@";;
    -eas) shift && disableAllActiveScanner && enableActiveScanner;;
    -eaas) shift && enableAllActiveScanner;;
    -daas) shift && disableAllActiveScanner;;
    -as) shift && activeScan;;
    -h|*) usage ;;
  esac
done
