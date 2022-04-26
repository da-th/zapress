#!/bin/sh

green=`tput setaf 2`
reset=`tput sgr0`

dir=$(cd "$(dirname "$0")" && pwd)
self=$(basename $0)

proxy_host=localhost

usage() {
    cat << EOF

    Usage: $self -<option>
      -${green}shownode${reset}: ${green}SHOW${reset} of nvm used version of ${green}NODE${reset}
      -${green}confnode${reset}: ${green}CONF${reset}igure of nvm used version of ${green}NODE${reset} and update dependancies
      -${green}obmitnode${reset}: ${green}OBMIT${reset} of nvm used version of ${green}NODE${reset} back to the default one
      -${green}uenv${reset}: ${green}U${reset}pdate ${green}ENV${reset}ironment (juice shop + zap (both dockerized))
      -${green}renv${reset}: ${green}R${reset}un ${green}ENV${reset}ironment (docker)
      -${green}senv${reset}: ${green}S${reset}hutdown ${green}ENV${reset}ironment (docker)
      -${green}cd${reset}: run ${green}C${reset}ypress in ${green}D${reset}ocker container | <test type> <test scenario> <shop>
      -${green}cn${reset}: run ${green}C${reset}ypress ${green}N${reset}ative | <test type> <test scenario> <shop>
      -${green}cdhl${reset}: run ${green}C${reset}ypress in ${green}D${reset}ocker container, ${green}H${reset}eadless (chrome) on ${green}L${reset}ocal shop
      -${green}cdvl${reset}: run ${green}C${reset}ypress in ${green}D${reset}ocker container, ${green}V${reset}isual on ${green}L${reset}ocal shop
      -${green}cnhl${reset}: run ${green}C${reset}ypress ${green}N${reset}ative, ${green}H${reset}eadless (chrome) on ${green}L${reset}ocal shop
      -${green}cnvl${reset}: run ${green}C${reset}ypress in ${green}N${reset}ative, ${green}V${reset}isual on ${green}L${reset}ocal shop
      -${green}z${reset}: run ${green}Z${reset}ap | -<scan type> <shop>
      -${green}zahl${reset}: run ${green}Z${reset}ap ${green}A${reset}ctive-scan, ${green}H${reset}eadless on ${green}L${reset}ocal shop

EOF
  exit 1
}

# check running juice container
checkJuice() {
  status="$(curl -I -s 'http://localhost:3000')"
  if [ "$status" = "" ] ;then
    echo ""
    echo "#########################################"
    echo "OWASP Juice Shop is not available!"
    echo "Is the Juice Shop container running?"
    echo "#########################################"
    echo ""
    usage
    exit
  fi
}

showNode() {
  . ~/.nvm/nvm.sh
  echo "#############################################################"
  echo "Node info:"
  echo "$(nvm ls)"
  echo "#############################################################"
}

configureNode() {
  echo "switch node version for matching project needs..."
  . ~/.nvm/nvm.sh
  # use declarated node version (taken from ./.nvmrc)
  nvm use
  npm i
}

omitNode() {
  echo "switch node version to default..."
  . ~/.nvm/nvm.sh
  nvm use default
}

update() {
  echo "update test environment (juice shop + zap) in docker..."
  docker pull bkimminich/juice-shop
  echo ""
  docker pull owasp/zap2docker-stable
}

run() {
  echo "run test environment (juice shop + zap) in docker..."
  docker-compose -f zap_juice.yml up -d --build
}

shutdown() {
  echo "shutdown test environment in docker..."
  docker-compose -f zap_juice.yml down
}

cypressDocker() {
  echo "start Cypress in Docker container..."
  sh ./zap/scripts/zapScan.sh -eps
  sh ./cypress/scripts/runCypressTestsContainer.sh "$@"
}

cypressNative() {
  echo "start Cypress in Docker container..."
  sh ./zap/scripts/zapScan.sh -eps
  sh ./cypress/scripts/runCypressTests.sh "$@"
}

cypressDockerHeadlessLocal() {
  echo "start Cypress in Docker container headless on local juice shop..."
  cypressDocker test_chrome all local
}

cypressNativeHeadlessLocal() {
  echo "start Cypress as native headless on local juice shop..."
  cypressNative test_chrome all local
}

cypressDockerVisualLocal() {
  echo "start Cypress in Docker container in visual mode on local juice shop..."
  echo "Open 'http://localhost:6901/'in your browser!"
  cypressDocker start all local
}

cypressNativeVisualLocal() {
  echo "start Cypress as native in visual mode on local juice shop..."
  cypressNative start all local
}

zap() {
  echo "start ZAP..."
  sh ./zap/scripts/zapScan.sh "$@"
}

zapActiveHeadlessLocal() {
  echo "start ZAP active scan headless on local juice shop..."
  zap -as local
}

#####################################
# main
#####################################

cd $dir

while [ $# > 0  ]; do
  opt="$1"
  case "$opt" in
    -shownode) shift && showNode;;
    -confnode) shift && configureNode;;
    -omitnode) shift && omitNode;;
    -uenv) shift && update;;
    -renv) shift && run;;
    -senv) shift && shutdown;;
    -cd) shift && checkJuice && cypressDocker "$@";;
    -cn) shift && checkJuice && cypressNative "$@";;
    -cdhl) shift && checkJuice && cypressDockerHeadlessLocal;;
    -cdvl) shift && checkJuice && cypressDockerVisualLocal;;
    -cnhl) shift && checkJuice && cypressNativeHeadlessLocal;;
    -cnvl) shift && checkJuice && cypressNativeVisualLocal;;
    -z) shift && zap "$@";;
    -zahl) shift && zapActiveHeadlessLocal;;
    -h|*) usage ;;
  esac
done
