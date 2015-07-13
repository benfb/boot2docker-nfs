#!/bin/bash
# Use unofficial strict mode
set -euo pipefail
IFS=$'\n\t'

WORKSPACE=${1:-$HOME/src}
PACKAGES=(virtualbox vagrant)

if ! type "brew" > /dev/null; then
  echo "Homebrew needs to be installed for this to work properly."
  read "I can install it for you if you like. Is this okay? [y/n] " response
  echo
  case $response in
    y|Y|yes )
      ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)";;
    * )
      echo "Hombrew needs to be installed. Exiting..."
      exit 1;;
  esac
fi

if ! brew tap | grep "caskroom/cask" > /dev/null; then
  echo "Brew Cask needs to be installed for this to work properly."
  read "I can install it for you if you like. Is this okay? [y/n] " response
  echo
  case $response in
    y|Y|yes )
      brew install caskroom/cask/brew-cask;;
    * )
      echo "Brew cask needs to be installed. Exiting..."
      exit 1;;
  esac
fi

for pkg in ${PACKAGES}; do
  if ! brew cask list | grep "${pkg}" > /dev/null; then
    echo "Installing ${pkg}..."
    brew cask install ${pkg}
  fi
done

if ! type "docker-compose" > /dev/null; then
  echo "You need docker-compose to run Uncommon with Docker."
  read "I can install it for you if you like. Is this okay? [y/n] " response
  echo
  case $response in
    y|Y|yes )
      brew install docker-compose;;
    * )
      echo "docker-compose needs to be installed. Exiting..."
      exit 1;;
  esac
fi


if [ ! -f ${WORKSPACE}/Vagrantfile ] || [ ! -f ${WORKSPACE}/vagrant.yml ]; then
  echo "Getting the Vagrantfile from git..."
  git clone https://github.com/benfb/wonderwharf.git ${WORKSPACE}/wonderwharf
  echo "Moving relevant files into your workspace..."
  mv "${WORKSPACE}/wonderwharf/Vagrantfile" "${WORKSPACE}/Vagrantfile"
  mv "${WORKSPACE}/wonderwharf/vagrant.yml" "${WORKSPACE}/vagrant.yml"
fi

if ! grep "DOCKER_HOST" <${HOME}/.bash_profile > /dev/null; then
  echo "Adding DOCKER_HOST to your .bash_profile..."
  echo "export DOCKER_HOST=tcp://localhost:2375" >> ~/.bash_profile
fi

if [ -d ${WORKSPACE}/wonderwharf ]; then
  echo "Cleaning up..."
  rm -rf "${WORKSPACE}/wonderwharf"
fi

echo "You're all set!"
exit 0
