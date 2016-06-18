#!/bin/sh

serverlist="daqfxs agentrunner"
userlist="daq"

for server in $serverlist
do
    rm -rf ssh-server.$server
    mkdir ssh-server.$server
    cd ssh-server.$server
    ssh-keygen -t rsa -f ssh_host_rsa_key -N '' -C '' -q
    cd ..
    cp sshd_config ssh-server.$server
done

for user in $userlist
do
    rm -rf ssh-user.$user
    mkdir ssh-user.$user
    cd ssh-user.$user
    ssh-keygen -t rsa -f id_rsa -N '' -C '' -q
    for server in $serverlist
    do
        echo $(cat id_rsa.pub) daq@$server >> authorized_keys
        echo $server $(cat ../ssh-server.$server/ssh_host_rsa_key.pub) >> known_hosts
    done
    cd ..
done
