#! /bin/bash

# Set path to include rbenv
source $HOME/.bash_profile

#!/bin/bash

Help()
{
    # Display Help
    echo "Intrigue Core Management Script"
    echo
    echo "Syntax: ./intriguectl [start|stop]"
    echo "options:"
    echo "start  start intrigue services"
    echo "stop   stop intrigue services"
    echo
    echo "To set your basic auth password, export variable CORE_PASSWD"
    echo
}

SetPassword()
{
    if [ -f "${CORE_PASSWD}" ]; then
      FILE1=~/core/config/config.json
      FILE2=~/core/config/config.json.default
      if [ -f "$FILE1" ]; then
          sed -i "s/\"password\": \".*\"/\"password\": \"${CORE_PASSWD}\"/g" $FILE1
      elif [ -f "$FILE2" ]; then
          sed -i "s/\"password\": \".*\"/\"password\": \"${CORE_PASSWD}\"/g" $FILE2
      else
          echo "Failed to set basic auth password. Check that your installation is in your home directory"
      fi
    fi
    
}

Setup()
{
    # check if we are a worker (we don't need to setup database if we are)
    if [[ -z "${WORKER_CONFIG}" ]]; then
      echo "We are a worker-only configuration!"
      return
    fi
    
    # else we set up the databases configuration
    echo "[+] Intrigue is starting for the first time! Setting up..."
    # stop postgres service to make configuration changes
    sudo service postgres stop

    # Set up database if it's not already there 
    if [ ! -d /data/postgres ]; then
      echo "[+] Configuring postgres..."
      sudo mkdir -p /data/postgres
      sudo chown postgres:postgres /data/postgres 2>&1 /dev/null
      sudo -u postgres /usr/lib/postgresql/*/bin/initdb /data/postgres 2>&1 /dev/null
    fi 

    # now start the service 
    sudo service postgresql start

    # force user/db creation, just in case
    sudo -u postgres createuser intrigue 2>&1 /dev/null
    sudo -u postgres createdb intrigue_dev --owner intrigue 2>&1 /dev/null

    # Adjust and spin up redis
    echo "[+] Configuring redis..."
    if [ ! -d /data/redis ]; then
      sudo mkdir -p /data/redis
      sudo chown redis:redis /data/redis
    fi 

    # now we can starts services
    sudo service redis-server start

    # change to core's directory
    cd ~/core

    # migrade db
    echo "[+] Migrating Database..."
    bundle exec rake db:migrate

    # run setup
    echo "[+] Setting up Intrigue standalone..."
    bundle exec rake setup

    # configure god
    god -c ~/core/util/god/intrigue.rb
    touch .setup_complete
    
    echo "[+] Setup complete! Starting services..."
}

################################################################################
################################################################################
# Main program                                                                 #
################################################################################
################################################################################

cmd=$1

if [ -z "$cmd" ];
then
    Help
    exit
fi

if [ "$cmd" == "start" ]; then
    echo "Starting intrigue..."
    # set password
    SetPassword

    # check if setup has already run once
    FILE=~/core/.setup_complete
    if [ ! -f "$FILE" ]; then
       Setup
    fi

    # start services
    cd ~/core
    god start
    sleep 25
    ip=$(ifconfig eth0 | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1')
    echo "Browse to https://$ip:7777 and login with user 'intrigue' and the given or pregenerated password"

    # if we're in docker, we'll tail worker log
    if [ -f /.dockerenv ]; then
      tail -f /core/log/worker.log
    fi 
elif [ "$cmd" == "stop" ]; then
    cd ~/core
    god stop
else
    echo "Unknown command."
    Help
fi