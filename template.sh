#!/usr/bin/env bash
# set -eux -o pipefail

############################################################
# Global Vars                                              #
############################################################

BASEDIR=manifests
PORTPREF=60
NAMEPREF=vm
FILES=files
DEST=/etc/firecracker/manifests
TARGETHOST=${TARGETHOST:-127.0.0.1}
PUBKEY=${PUBKEY:-dev/id_rsa.pub}
PRIVATEKEY=${PRIVATEKEY:-dev/id_rsa}

############################################################
# Helpers                                              #
############################################################

pushd () {
    command pushd "$@" > /dev/null
}

popd () {
    command popd "$@" > /dev/null
}

############################################################
# Help                                                     #
############################################################
Help()
{
  # Display Help
  echo "Syntax: ./template.sh [-h|i|k]"
  echo "options:"
  echo "h     Print this Help."
  echo "i     identifier for your vm prefix. Please check the ./manifests directory -"
  echo "      and choose something unique such as your intials or another  interesting/useful piece of trivia"
  echo "k     the ABSOLUTE path of the public key to insert in your remote instance"
  echo
}

############################################################
# Template
############################################################
Template()
{
  INV=$(ls manifests/ | wc -l)
  NUM=$(( $INV - 1 ))
  PAD=`printf %03d $NUM`
  NAME="$NAMEPREF-$INIT-$PAD"
  SSHPORT="$PORTPREF$PAD"
  KEYNAME=$(basename $KEY)
  DESTLOC=$DEST/$NAME/$KEYNAME
  FILESLOC=$DEST/$FILES
  DOCKERCONF=$FILESLOC/daemon.json
  UUIDGEN=$(hexdump -vn8 -e'4/4 "%08X" 1 "\n"' /dev/urandom | tr "[:upper:]" "[:lower:]" | xargs)
  echo "... the chosen vm-name is $NAME "
  echo "... the chosen public key path is $KEY ..."

  pushd $BASEDIR
  mkdir -p $NAME
  cp $KEY $NAME
  popd

  rm /tmp/temp.yaml
  ( echo "cat <<EOF >$BASEDIR/$NAME/vm.yaml";
    cat template.yaml;
    echo "EOF";
  ) >/tmp/temp.yaml
  . /tmp/temp.yaml
  echo "==============================================="
  echo "your developer environment configuration is:"
  cat $BASEDIR/$NAME/vm.yaml
  echo "==============================================="
  echo "Please add the below to your \$USER/.ssh/config"
  echo "Host ${NAME}"
  echo "  User root"
  echo "  Hostname 127.0.0.1"
  echo "  ProxyJump ${TARGETHOST}"
  echo "  Port ${SSHPORT}"
  echo "  IdentityFile ${PRIVATEKEY} # You will need to replace with your own private key"
  echo "  IdentitiesOnly yes"
  echo "  StrictHostKeyChecking no"
  echo "  PasswordAuthentication no"
  echo "==============================================="
}

############################################################
############################################################
# Main program                                             #
############################################################
############################################################
while getopts ":i:h:k:" option; do
  case $option in
    h) # display Help
      Help
      exit;;
    i)
      INIT=${OPTARG}
      ;;
    k)
      KEY=${OPTARG}
      ;;
    *)
      exit;;
  esac
done

if [ -z "${i}" ] || [ -z "${k}" ]; then
    Template
else
    Help
fi
