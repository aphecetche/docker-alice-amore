#! /bin/sh
#
# A bunch of methods to ease the work with docker containers
# for amore
#
# Most of the functions here (except the one starting with ali_make_ which
# are used only once by the ali_bootstrap command) assume that the 
# docker-compose up -d command has been executed so the required 
# containers are running.
#
#

ali_docker_run() {
    #ali_xquartz_if_not_running
    #docker run -e DISPLAY=$(ali_getmyip):0 -v /tmp/.X11-unix:/tmp/.X11-unix \
        # -v /etc/localtime:/etc/localtime -e TZ="Europe/Paris" $@

    docker run -e DISPLAY=:0 -v /tmp/.X11-unix:/tmp/.X11-unix -v /etc/localtime:/etc/localtime -e TZ="Europe/Paris" $@
}

ali_volumes()
{
    echo "vc_amore_site vc_date_site vc_date_db vc_amore_cdb vc_daq_fxs vc_home_daq vc_home_dqm vc_ssh_daqfxs vc_ssh_agentrunner"
}

ali_date() {
    local host_name=$1
    local command=${2:-/bin/bash}
    ali_docker_run -it --rm \
        -v vc_date_site:/dateSite \
        -v vc_date_db:/var/lib/mysql \
        -v vc_daq_fxs:/daqfxs \
        -v vc_home_daq:/home/daq \
        -v vc_home_dqm:/home/dqm \
        --net dockeraliceonline_default \
        --name=$host_name \
        --hostname=$host_name \
        alice-date \
        $command
}

ali_did() {
    ali_date did /opt/dim/linux/did
}

ali_amore() {
    # create an amore container
    # with the proper links etc...
    # that can be used for the amore (modules) binaries
    local host_name=$1
    ali_docker_run -it --rm \
        -v vc_date_site:/dateSite \
        -v vc_date_db:/var/lib/mysql \
        -v vc_amore_site:/amoreSite \
        -v vc_daq_fxs:/daqfxs \
        -v vc_home_daq:/home/daq \
        -v vc_amore_cdb:/local/cdb \
        --net dockeraliceonline_default \
        --name=$host_name \
        --hostname=$host_name \
        alice-amore \
        /bin/bash
}

ali_amore_dev() {
    # create an amore container
    # with the proper links etc...
    # than can be used to compile amore core libraries and debug them
    # note the vc_amore_site_dev (_dev) volume, vs vc_amore_site (no _dev)
    # for the other functions above
    local host_name=$1
    ali_docker_run -it --rm \
        -v vc_date_site:/dateSite \
        -v vc_date_db:/var/lib/mysql \
        -v vc_amore_site_dev:/amoreSite \
        -v vc_amore_cdb:/local/cdb \
        -v vc_amore_opt:/opt/amore \
        -v ${HOME}/alicesw/run2/amore_modules/:/amore_modules \
        -v ${HOME}/alicesw/run2/amore/:/amore \
        -v ${HOME}/.globus:/root/.globus \
        --link dockeraliceonline_datedb_1 \
        --link dockeraliceonline_dim_1 \
        --link dockeraliceonline_infologger_1 \
        --net dockeraliceonline_default \
        --hostname=$host_name \
        --cap-add sys_ptrace \
        --name=$host_name \
        alice-online-devel \
        /bin/bash
}

ali_amore_modules_dev() {
    # create an amore container
    # with the proper links etc...
    # than can be used to compile amore modules
    local host_name=$1
    ali_docker_run -it --rm \
        -v vc_date_site:/dateSite \
        -v vc_date_db:/var/lib/mysql \
        -v vc_amore_site:/amoreSite \
        -v vc_amore_cdb:/local/cdb \
        -v ${HOME}/alicesw/run2/amore_modules/:/amore_modules \
        -v ${HOME}/.globus:/root/.globus \
        --link dockeraliceonline_datedb_1 \
        --link dockeraliceonline_dim_1 \
        --link dockeraliceonline_infologger_1 \
        --net dockeraliceonline_default \
        -e DATE_SITE=/dateSite \
        --name=$host_name \
        --hostname=$host_name \
        --cap-add sys_ptrace \
        alice-online-devel \
        /bin/bash
}

ali_da_dev() {
    local hostname=${1:-"dadev"}
    local detectorcode=${2:-"MCH"}
    local runnumber=${3:-123}
    ali_docker_run -it --rm \
        -v $(pwd):/daoutput \
        -v vc_date_site:/dateSite \
        -v vc_date_db:/var/lib/mysql \
        -v vc_amore_site:/amoreSite \
        -v vc_amore_cdb:/local/cdb \
        -v vc_daq_fxs:/daqfxs \
        -v vc_da_sw:/alicesw/sw \
        -v ${HOME}/.globus:/root/.globus:ro \
        -v ${HOME}/alicesw/run2/aliroot-date/AliRoot:/alicesw/AliRoot:ro \
        -v ${HOME}/alicesw/run2/aliroot-date/alidist:/alicesw/alidist:ro \
        -v ${HOME}/alicesw/repos/AliRoot:$HOME/alicesw/repos/AliRoot:ro \
        --link dockeraliceonline_datedb_1 \
        --link dockeraliceonline_dim_1 \
        --link dockeraliceonline_infologger_1 \
        --net dockeraliceonline_default \
        --hostname ${hostname} \
        --name ${hostname} \
        -e DATE_DETECTOR_CODE="$detectorcode" \
        -e DATE_SITE=/dateSite \
        -e DATE_RUN_NUMBER=${runnumber} \
        -e DATE_ROLE_NAME=da \
        -e ALI_WHAT=AliRoot \
        -e ALI_VERSION=date \
        --cap-add sys_ptrace \
       alice-online-devel \
       /bin/bash
}

ali_getrunnumber() {
    # very dump version that assume the given filename
    # can not be any else than a pristine raw data chunk name
    # in the form YY000123456ZZZ.chunknumber.raw
    local file=$(basename $1)
    echo ${file:5:6}
}

ali_callda() {
    local daname=$1
    local detectorcode=$2
    local amore_da_name=$3
    # insure rawfile is an absolute path
    pushd
    local rawfile=$(cd "$(dirname "$4")"; pwd)/$(basename "$4")
    popd
    local daexe=${daname/-}da.exe

    if [ "$daname" = "MCH-OCC" ]; then
        daexe="MUONTRKOCCda.exe"
    fi

    docker run -it --rm \
        -v $rawfile:/file.raw \
        -v $(pwd):/daoutput \
        -v vc_date_site:/dateSite \
        -v vc_date_db:/var/lib/mysql \
        -v vc_amore_site:/amoreSite \
        -v vc_amore_cdb:/local/cdb \
        -v vc_daq_fxs:/daqfxs \
        -v vc_daqDA-$daname:/opt/daqDA-$daname \
        -v /etc/localtime:/etc/localtime \
        -e TZ="Europe/Paris" \
        --link dockeraliceonline_datedb_1 \
        --link dockeraliceonline_dim_1 \
        --link dockeraliceonline_infologger_1 \
        --net dockeraliceonline_default \
        -e DATE_DETECTOR_CODE="$detectorcode" \
        -e DATE_SITE=/dateSite \
        -e DATE_RUN_NUMBER=$(ali_getrunnumber $rawfile) \
        -e DATE_ROLE_NAME=${amore_da_name} \
        -w /daoutput \
        alice-amore \
        /opt/daqDA-$daname/$daexe /file.raw
}

ali_callda_dev() {
    local dapath=$1 # dapath _must_ be an absolute path
    # otherwise the -v $rawfile:/file.raw will mount a directory ...
    local detectorcode=$2
    local amore_da_name=$3
    local rawfile=$4
    local runnumber=$(ali_getrunnumber $rawfile)
    docker run -it --rm \
        -v ${rawfile}:/file.raw \
        -v $(pwd):/daoutput \
        -v vc_date_site:/dateSite \
        -v vc_date_db:/var/lib/mysql \
        -v vc_amore_site:/amoreSite \
        -v vc_amore_cdb:/local/cdb \
        -v vc_da_sw:/alicesw/sw \
        -v vc_daq_fxs:/daqfxs \
        --link dockeraliceonline_datedb_1 \
        --link dockeraliceonline_dim_1 \
        --link dockeraliceonline_infologger_1 \
        --net dockeraliceonline_default \
        -e DATE_DETECTOR_CODE="$detectorcode" \
        -e DATE_SITE=/dateSite \
        -e DATE_RUN_NUMBER=$runnumber \
        -e DATE_ROLE_NAME=${amore_da_name} \
        alice-online-devel \
        $dapath /file.raw
}

ali_da_mchbpevo() {
    ali_callda MCH-BPEVO MCH mon-DA-MCH-1 $1
}

ali_da_mchocc() {
    ali_callda MCH-OCC MCH mon-DA-MCH-0 $1
}

ali_da_mchped() {
    ali_callda MCH-PED MCH ldc-MUON-TRK-0 $1
}

ali_da_dev_mchbpevo() {
    # insure rawfile is an absolute path for callda
    local rawfile=$(cd "$(dirname "$1")"; pwd)/$(basename "$1")
    ali_callda_dev /alicesw/sw/slc6_x86-64/AliRoot/latest/bin/MCHBPEVOda.exe MCH mon-DA-MCH-1 $rawfile
}

ali_infoBrowser() {

    # create an amore container
    # with the proper links etc...
    # to run the infobrowser
    ali_docker_run -it --rm \
        -v vc_date_site:/dateSite \
        -v vc_date_db:/var/lib/mysql \
        --net dockeraliceonline_default \
        -e DATE_SITE=/dateSite \
        --name infoBrowser \
        alice-date \
       /launch_infoBrowser.sh
}

ali_amoreGui() {
    # create an amore container
    # with the proper links etc...
    # to run amoreGui

    local index=${1:-""}

    ali_docker_run --rm \
        -v vc_date_site:/dateSite \
        -v vc_date_db:/var/lib/mysql \
        -v vc_amore_site:/amoreSite \
        -v $PWD/ssh-user.daq:/home/daq/.ssh \
        -v vc_amore_cdb:/local/cdb \
        --link dockeraliceonline_dim_1 \
        --net dockeraliceonline_default \
        -e DATE_SITE=/dateSite \
        --name amoreGui$index \
        alice-amore \
       /launch_amoreGui.sh
}

ali_generate_ssh_configs() {

    serverlist="daqfxs agentrunner"
    userlist="daq dqm"

    for server in $(echo $serverlist | tr " " "\n")
    do
        echo $server
        rm -rf ssh-server.$server
        mkdir ssh-server.$server
        cd ssh-server.$server
        ssh-keygen -t rsa -f ssh_host_rsa_key -N '' -C '' -q
        cd ..
        cp sshd_config ssh-server.$server
    done

    for user in $(echo $userlist | tr " " "\n")
    do
        rm -rf ssh-user
        mkdir ssh-user
        cd ssh-user
        ssh-keygen -t rsa -f id_rsa -N '' -C '' -q
        touch authorized_keys known_hosts
        for server in $(echo $serverlist | tr " " "\n")
        do
            echo $(cat id_rsa.pub) $user@$server >> authorized_keys
            echo $server $(cat ../ssh-server.$server/ssh_host_rsa_key.pub) >> known_hosts
        done
        echo "Protocol 2" > config
        echo "StrictHostKeyChecking no" >> config
        cd ..

        # now put the ssh-user directory into a volume
        docker volume create --name vc_home_$user
        docker run --name tmp$user -v vc_home_$user:/home/$user hepsw/slc-base rm -rf /home/$user/.ssh
        docker cp ssh-user tmp$user:/home/$user/.ssh
        docker rm tmp$user

        rm -rf ssh-user
    done

    for server in $(echo $serverlist | tr " " "\n")
    do
        docker volume create --name vc_ssh_$server
        docker run --name tmp$server -v vc_ssh_$server:/etc/ssh hepsw/slc-base /bin/true
        docker cp ssh-server.$server/. tmp$server:/etc/ssh
        docker rm tmp$server
        rm -rf ssh-server.$server
    done
    }

    ali_make_volumes() {

        for vol in $(echo $(ali_volumes) | tr " " "\n")
        do
            docker volume create --name $vol
        done
    }

    ali_remove_volumes() {

    echo "WARNING : you are about to remove the following volumes"
    echo $(ali_volumes)
    read -p "Are you sure you want to do that (yes/no) ? " YESNO

    if [ "$YESNO" == "yes" ]; then

            for vol in $(echo $(ali_volumes) | tr " " "\n")
            do
                    docker volume rm $vol
            done
    fi
    }

    ali_make_images() {

      # download our base images
      docker-compose pull datedb
      docker-compose pull phpmyadmin

      # build the alice-date image
      docker-compose build dim
      # build the alice-amore image
      docker-compose build agentrunner
      # build the alice-online-devel image
      docker-compose build dadev
      # build the alice-more image
      docker-compose build archiver
      # build the alice-online-devel
      docker-compose build dadev
    }

    ali_make_datedb() {

      ali_make_volumes

      # get the mysql server up
      docker-compose up -d datedb

      # wait for mysql to come up
      sleep 10

      # create the databases
      docker run -i --rm -v vc_date_db:/var/lib/mysql --net \
         dockeraliceonline_default alice-date /date/.commonScripts/newMysql.sh <<EOF
      datedb
      date
      DATE_CONFIG
      DATE_LOG
      ECS_CONFIG
      LOGBOOK
      daq daq
EOF

      # populate the databases
      docker run -i --rm \
          -v vc_date_site:/dateSite \
          -v vc_date_db:/var/lib/mysql \
          --net dockeraliceonline_default alice-date \
          /date/.commonScripts/newDateSite.sh <<EOF
      /dateSite
      DATE_CONFIG daq daq datedb
      root
      dim
      DATE
      DATE_LOG daq daq datedb
      LOGBOOK daq daq datedb
      y
      DAQ_TEST
      y
      y
EOF


    # tweak the DATE_INFOLOGGER_LOGHOST which is not correctly set by the
    # newDataSite.sh script

      docker run -i --rm \
          -v vc_date_site:/dateSite \
          -v vc_date_db:/var/lib/mysql \
          --net dockeraliceonline_default alice-date \
        /date/db/Linux/daqDB_query "UPDATE ENV SET VALUE=\"infologger\" WHERE NAME=\"DATE_INFOLOGGER_LOGHOST\";"

    }

    ali_make_amoredb() {
    
        ali_make_volumes

        # get the mysql server up
        docker-compose up -d datedb
    
        # wait a bit for it to come up
        sleep 10

        # create the amore database
        
        docker run -i --rm -v vc_date_db:/var/lib/mysql \
            --net dockeraliceonline_default \
            --entrypoint /bin/bash \
            -e AMORE=/opt/amore \
            -e PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/amore/bin \
            alice-amore \
            /opt/amore/bin/amoreMysqlSetup <<EOF
        datedb
        date
        AMORE
        daq daq
EOF

        # mount once the vc_amore_site volume so it is
        # populated with the initial image content
        docker run --rm -v vc_amore_site:/amoreSite \
            -v vc_date_db:/var/lib/mysql \
            --net dockeraliceonline_default \
            alice-amore \
            /bin/true

        docker-compose down
    }
    

    ali_bootstrap() {

      # - create a default mysql DATE database
      # - build/download all the required images
      # - create all data volumes

      # to be able to use any of the docker-compose commands
      # we must first get all the data volumes declared in
      # the docker-compose.yml file created

      ali_make_volumes

      ali_make_images

      ali_make_datedb

      ali_make_amoredb

      docker-compose down
    }

    ali_make_volume_for_da() {
        local daname=$1 # DA name, without the daqDA- prefix, e.g. MCH-BPEVO or MCH-PED
        local volume_name=vc_daqDA-${daname}

        docker volume create --name ${volume_name}

        docker run --rm \
        -v vc_date_site:/dateSite \
        -v vc_date_db:/var/lib/mysql \
        -v ${volume_name}:/opt/daqDA-${daname} \
        --net dockeraliceonline_default \
        --name tmp$daname \
        alice-date \
        yum install -y daqDA-$daname
    }

    ali_install_amore_modules() {

        # install a bunch of modules (without the amore prefix, e.g. MCH, DB, TRI,
        # and not amoreMCH, amoreDB, ...)
        # in vc_amore_site volume

        for module in $@
        do
            docker run --rm -v vc_amore_site:/amoreSite \
                --net dockeraliceonline_default \
                --link dockeraliceonline_datedb_1 \
                alice-amore \
                yum install -y amore${module}
        done
    }

ali_daqFES_ls() {

docker run -it --rm \
        -v vc_date_site:/dateSite \
        -v vc_date_db:/var/lib/mysql \
        -v vc_daq_fxs:/daqfxs \
        -v vc_home_daq:/home/daq \
        -v vc_home_dqm:/home/dqm \
        --net dockeraliceonline_default \
        alice-date \
        /date/infoLogger/daqFES_ls
}

ali_daqFES_get() {


docker run -it --rm \
        -v vc_date_site:/dateSite \
        -v vc_date_db:/var/lib/mysql \
        -v vc_daq_fxs:/daqfxs \
        -v vc_home_daq:/home/daq \
        -v vc_home_dqm:/home/dqm \
        -v $(pwd):/tmp \
        --net dockeraliceonline_default \
        -w /tmp \
        alice-date \
        /date/infoLogger/daqFES_get $1
}
