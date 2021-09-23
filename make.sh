#!/bin/sh

green=`tput setaf 2`
reset=`tput sgr0`

dir=$(cd "$(dirname "$0")" && pwd)
self=$(basename $0)

proxy_host=localhost

usage() {
    cat << EOF

    Usage: $self -<option>
      -${green}renv${reset}: ${green}R${reset}un ${green}ENV${reset}ironment (juice shop + zap (both dockerized))
      -${green}senv${reset}: ${green}S${reset}hutdown ${green}ENV${reset}ironment (docker)
      -${green}lenv${reset}: ${green}L${reset}eave ${green}ENV${reset}ironment (docker swarm)
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

show_node() {
  echo "#############################################################"
  echo "# Node info:"
  echo $(nvm ls)
  echo "#############################################################"
}

configure_node() {
  echo "switch node version for matching project needs..."
  #export NVM_DIR=$HOME/.nvm;
  #source $NVM_DIR/nvm.sh;
  # use declarated node version (taken from .nvmrc)
  nvm use
  npm i
}

omit() {
  echo "switch node version to newest installed..."
  # use newest installed node version
  nvm use node
}

run() {
  echo "run test environment (juice shop + zap) in docker..."
  #local_ip=$(ip route get 8.8.8.8 | awk -F"src " 'NR==1{split($2,a," ");print a[1]}')
  #docker swarm init --advertise-addr $local_ip
  #docker stack deploy -c docker-compose.yml demo_test_app
  docker-compose -f zap_juice.yml up -d --build
}

shutdown() {
  echo "shutdown test environment in docker..."
  docker-compose -f zap_juice.yml down
}

leave() {
  echo "leave test environment in docker swarm..."
  docker swarm leave --force
}

cypress_docker() {
  echo "start Cypress in Docker container..."
  sh ./zap/scripts/zapScan.sh -pso
  sh ./cypress/scripts/runCypressTestsContainer.sh "$@"
}

cypress_native() {
  echo "start Cypress in Docker container..."
  sh ./zap/scripts/zapScan.sh -pso
  sh ./cypress/scripts/runCypressTests.sh "$@"
}

cypress_docker_headless_local() {
  echo "start Cypress in Docker container headless on local juice shop..."
  cypress_docker test_chrome all local
}

cypress_native_headless_local() {
  echo "start Cypress as native headless on local juice shop..."
  cypress_native test_chrome all local
}

cypress_docker_visual_local() {
  echo "start Cypress in Docker container in visual mode on local juice shop..."
  echo "Open 'http://localhost:6901/'in your browser!"
  cypress_docker start all local
}

cypress_native_visual_local() {
  echo "start Cypress as native in visual mode on local juice shop..."
  cypress_native start all local
}

zap() {
  echo "start ZAP..."
  sh ./zap/scripts/zapScan.sh "$@"
}

zap_active_headless_local() {
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
    -shownode) shift && show_node;;
    -confnode) shift && configure_node;;
    -omitnode) shift && omit;;
    -renv) shift && run;;
    -senv) shift && shutdown;;
    -lenv) shift && leave ;;
    -cd) shift && cypress_docker "$@";;
    -cn) shift && cypress_native "$@";;
    -cdhl) shift && cypress_docker_headless_local;;
    -cdvl) shift && cypress_docker_visual_local;;
    -cnhl) shift && cypress_native_headless_local;;
    -cnvl) shift && cypress_native_visual_local;;
    -z) shift && zap "$@";;
    -zahl) shift && zap_active_headless_local;;
    -h|*) usage ;;
  esac
done
