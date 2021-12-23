#!/bin/bash


if [ $# == 0 ]
then
  # make temp dir for operator files
  mkdir tmp-limitador && cd tmp-limitador

  # clone limitador-operator repo
  git clone https://github.com/Kuadrant/limitador-operator.git .

  # select project for proper installation
  oc project apicurio-registry

  # deploy limitador operator
  echo "Creating limitador CRDs and deploying operator system"
  make deploy && cd ..
fi

if [ "$1" == "cleanup" ]
then
# remove tmp dir
  cd tmp-limitador &&  make undeploy
  cd ../ && rm -rf tmp-limitador
fi