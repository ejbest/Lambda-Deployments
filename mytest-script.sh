#!/usr/bin/env bash


# make script exit when a command fails.
set -o errexit
#The exit status of the last command that threw a non-zero exit code is returned.
set -o pipefail
# set -o nounset
# set -o xtrace

# get the directory where the script is running.
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )";

# $1: function name
# $2: Config Key
# @return it echoes the Config Value mapped to the Config key
#         for a given function
function get_config_value {
  function_name=$1;
  # parse the configuration of the function until reaching ">>>>"
  configset=$(sed -n '/>>>>'"$function_name"'/,/>>>>/p' "${DIR}/Deployfile");
  # get value and remove and trim
  value=$(echo "$configset" | grep "${2}" |cut -d'=' -f2 | xargs);
  if [ "$3" == "--no-space" ]; then
    # remove all white spaces
    echo $value | tr -d ' ';
  else
    echo $value;
  fi
};

# $1: function_name -  The name of the function
# $2: dryrun - has two values "yes", "no"
function build_aws_lambda_create_function {
  command=$(cat << EOF
  aws lambda create-function \
  --function-name $(get_config_value ${1} FunctionName) \
  --runtime $(get_config_value ${1} Runtime) \
  --role "$(get_config_value ${1} Role)" \
  --zip-file $(get_config_value ${1} ZipFile) \
  --handler $(get_config_value ${1} Handler) \
  --timeout $(get_config_value ${1} Timeout) \
  --description "$(get_config_value ${1} Description)" \
  --memory-size $(get_config_value ${1} MemorySize) \
  --vpc-config "SubnetIds=$(get_config_value ${1} SubnetIds --no-space),SecurityGroupIds=$(get_config_value ${1} SecurityGroups --no-space)" \
  --tracing-config $(get_config_value ${1} TracingConfig | sed "s/ : /=/g" )
EOF
);
  # check if dry-run or not
  if [ "${2}" = "yes" ]; then
    echo $command;
  else
    eval $command;
  fi


}

# remember you must give "--zip-file" or "--code"
function build_all {
  # loop through all arguments
  dryrun="no";
  if [ "${1}" = "--dry-run" ]; then

    dryrun="yes";
    shift;
  fi

  functions="$@";

  # if no args
  if [ $# -eq 0 ]; then

    functions=$(grep  "^>>>>" "${DIR}/Deployfile" | cut -c 5-);

  fi

  eval "array_functions=($functions)"
  for fn in "${array_functions[@]}";
  do

    build_aws_lambda_create_function $fn $dryrun
  done
}

# Use $@
build_all  $@;
# if [ "$1" == "dry-run" ]; then

# EOF

# else
#   main
# fi
