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

ali_getmyip() {

    ip route get 8.8.8.8 | head -1 | cut -d' ' -f8
}

ali_xquartz_if_not_running() {
    #
    # check (and start if not running) that xquartz is
    # running (MAC OSX ONLY)
    #
    v_nolisten_tcp=$(defaults read org.macosforge.xquartz.X11 nolisten_tcp)
    v_xquartz_app=$(defaults read org.macosforge.xquartz.X11 app_to_run)

    if (( $v_nolisten_tcp == 1 )); then
        defaults write org.macosforge.xquartz.X11 nolisten_tcp 0
    fi

    if [ $v_xquartz_app != "/usr/bin/true" ]; then
        defaults write org.macosforge.xquartz.X11 app_to_run /usr/bin/true
    fi

    # test if XQuartz has to be launched
    #
    if [[ "$(launchctl list | grep startx | cut -c 1)" == "-" ]]; then
        open -a XQuartz
        sleep 2
    fi
}

ali_docker_run() {

    # a wrapper to "docker run" to get X11 display working
    # correctly

    case "$OSTYPE" in
        darwin*)
            ali_xquartz_if_not_running
            ;;
    esac


    case "$OSTYPE" in
        darwin*)
            docker run -e DISPLAY=$(ali_getmyip):0 -v /tmp/.X11-unix:/tmp/.X11-unix -v /etc/localtime:/etc/localtime -e TZ="Europe/Paris" $@
            xhost +$(ali_getmyip)
            ;;
        *)
            docker run -e DISPLAY=unix$DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix -v /etc/localtime:/etc/localtime -e TZ="Europe/Paris" $@
            xhost + # fixme, there should be a better way...
        ;;
    esac
}

ali_volumes() {
    echo "vc_amore_site vc_date_site vc_date_db vc_amore_cdb vc_daq_fxs vc_home_daq vc_home_dqm vc_ssh_daqfxs vc_ssh_agentrunner vc_da_sw vc_daqDA-MCH-BPEVO vc_daqDA-MCH-OCC vc_daqDA-MCH-PED"
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

ali_pt2_root() {
    ali_docker_run -it --rm \
        -v vc_date_site:/dateSite \
        -v vc_date_db:/var/lib/mysql \
        -v vc_amore_site:/amoreSite \
        -v vc_daq_fxs:/daqfxs \
        -v vc_home_daq:/home/daq \
        -v vc_amore_cdb:/local/cdb \
        -v $(pwd):/localdrive \
        --net dockeraliceonline_default \
        alice-amore \
        /opt/root/bin/root.exe
}

ali_amore() {
    # create an amore container
    # with the proper links etc...
    # that can be used for the amore (modules) binaries
    local host_name=$1
    local cmd=${2:-/bin/bash}
    local tty=""
    if [ $# -gt 2 ]; then
        tty="t"
    fi
    ali_docker_run -i$tty --rm \
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
        $cmd
    return $?
}

ali_dev_env() {

    # define some variables indicating where
    # to find, locally (i.e. on your host, not in the containers)
    # the code to be developped

    export ALI_DEV_ENV_PATH_AMORE=${ALI_DEV_ENV_PATH_AMORE:-$HOME/alicesw/run2/amore}
    export ALI_DEV_ENV_PATH_AMORE_MODULES=${ALI_DEV_ENV_PATH_AMORE_MODULES:-$HOME/alicesw/run2/amore_modules}
    export ALI_DEV_ENV_PATH_DOTGLOBUS=${ALI_DEV_ENV_PATH_DOTGLOBUS:-${HOME}/.globus}
    export ALI_DEV_ENV_PATH_ALIROOT_DATE=${ALI_DEV_ENV_PATH_ALIROOT_DATE:-$HOME/alicesw/run2/aliroot-date}
}

ali_check_dir() {

    if ! test -d "$1"; then
        ali_echo_error "Directory $1 does not exist !"
        return 1
    fi
    return 0
}

ali_amore_dev() {
    # create an amore container
    # with the proper links etc...
    # than can be used to compile amore core libraries and debug them
    # note the vc_amore_site_dev (_dev) volume, vs vc_amore_site (no _dev)
    # for the other functions above

    ali_dev_env

    ali_check_dir ${ALI_DEV_ENV_PATH_AMORE_MODULES} || return
    ali_check_dir ${ALI_DEV_ENV_PATH_AMORE} || return
    ali_check_dir ${ALI_DEV_ENV_PATH_DOTGLOBUS} || return

    local host_name=$1

    ali_docker_run -it --rm \
        -v vc_date_site:/dateSite \
        -v vc_date_db:/var/lib/mysql \
        -v vc_amore_site_dev:/amoreSite \
        -v vc_amore_cdb:/local/cdb \
        -v vc_amore_opt:/opt/amore \
        -v ${ALI_DEV_ENV_PATH_AMORE_MODULES}:/amore_modules \
        -v ${ALI_DEV_ENV_PATH_AMORE}:/amore \
        -v ${ALI_DEV_ENV_PATH_DOTGLOBUS}:/root/.globus \
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

    ali_dev_env

    ali_check_dir ${ALI_DEV_ENV_PATH_DOTGLOBUS} || return
    ali_check_dir ${ALI_DEV_ENV_PATH_ALIROOT_DATE} || return

    local hostname=${1:-"dadev"}
    local detectorcode=${2:-"MCH"}
    local runnumber=${3:-123}
#        -v ${HOME}/alicesw/repos/AliRoot:$HOME/alicesw/repos/AliRoot:ro \

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
        -v vc_home_daq:/home/daq \
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
            docker volume create --name $vol || return 1
        done
        return 0
    }

    ali_remove_volumes() {

    echo "WARNING : you are about to remove the following volumes"
    echo $(ali_volumes)
    echo -n "Are you sure you want to do that (yes/no) ? "
    read YESNO

    echo "YESNO=$YESNO"
    if  [ "$YESNO" = "yes" ]; then

            for vol in $(echo $(ali_volumes) | tr " " "\n")
            do
                    docker volume rm $vol
            done
    fi
    return 0
    }

    ali_daqDB_query() {
      docker run -i --rm \
          -v vc_date_site:/dateSite \
          -v vc_date_db:/var/lib/mysql \
          --net dockeraliceonline_default alice-date \
          /date/db/Linux/daqDB_query "$1"
      return $?
    }

    ali_make_images() {

      # download our base images
      docker-compose pull datedb || return 1
      docker-compose pull phpmyadmin || return 2

      # build the alice-date image
      docker-compose build dim || return 3
      # build the alice-amore image
      docker-compose build agentrunner || return 4
      # build the alice-online-devel image
      docker-compose build dadev || return 5
      # build the alice-more image
      docker-compose build archiver || return 6
      # build the alice-online-devel
      docker-compose build dadev || return 7
      return 0
    }

    ali_up_datedb() {

      # get the mysql server up
      docker-compose up -d datedb || return 1

      n="0"

      while [ $n -lt 60 ]
      do
          # try to access a database to know if mysql has indeed started
        docker-compose exec datedb \
            mysql -uroot -pdate -hlocalhost -e "use mysql" > /dev/null 2>&1

          if [ $? -eq 0 ]; then
              echo "datedb is up after $n attempts"
              return 0
          else
              sleep 1
          fi
          n=$[$n+1]
      done

      return 1 
    }

    ali_make_datedb() {

      ali_make_volumes || return 1

      ali_up_datedb || return 2

      ali_echo "datedb is up. Calling newMysql.sh"

      # create the databases
      docker run -i --rm \
          -v vc_date_db:/var/lib/mysql \
          --net dockeraliceonline_default \
          alice-date \
          /date/.commonScripts/newMysql.sh <<EOF
      datedb
      date
      DATE_CONFIG
      DATE_LOG
      ECS_CONFIG
      LOGBOOK
      daq daq
EOF
    if [ $? -ne 0 ]; then
        return 3
    fi

    ali_echo "Databases created"

      # populate the databases
    docker run -i --rm \
        -v vc_date_site:/dateSite \
        -v vc_date_db:/var/lib/mysql \
        --net dockeraliceonline_default \
        alice-date \
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

    if [ $? -ne 0 ]; then
        return 4
    fi

    ali_echo "Databases populated"

    # tweak the DATE_INFOLOGGER_LOGHOST which is not correctly set by the
    # newDataSite.sh script


    ali_daqDB_query "UPDATE ENV SET VALUE=\"infologger\" WHERE NAME=\"DATE_INFOLOGGER_LOGHOST\";"

    docker-compose up -d infologger

    sleep 10

    # set the FES access information
    ali_daqDB_query "INSERT INTO ENV VALUES ('DATE_FES_DB','daq:daq@datedb/DATE_LOG','Database','',1);" || return 5

    ali_daqDB_query "INSERT INTO ENV VALUES ('DATE_FES_PATH','/daqfxs','Database','',1);" || return 6

    docker-compose down || return 7

    return 0
}

    ali_make_amoredb() {

        ali_make_volumes || return 1

        ali_up_datedb || return 2

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

    if [ $? -ne 0 ]; then
        return 3
    fi

        # mount once the vc_amore_site volume so it is
        # populated with the initial image content
        docker run --rm -v vc_amore_site:/amoreSite \
            -v vc_date_db:/var/lib/mysql \
            --net dockeraliceonline_default \
            alice-amore \
            /bin/true || return 4

        docker-compose down || return 5
        return 0
    }


    ali_make_agents() {

        # create a few default agents
        # feel free to add yours here

      ali_up_datedb

      ali_echo "Making agent MCHQAshifter"

      ali_amore tmpMCHQAshifter /opt/amore/bin/newAmoreAgent > /dev/null  2>&1 <<EOF
      MCHQAshifter
      runner-mchqashifter
      agentMCHQAshifter
      QA
      QA
      :
      PublisherQA
EOF

      ali_echo "Making agent MCHQC"
      ali_amore tmpMCHQC /opt/amore/bin/newAmoreAgent > /dev/null 2>&1 <<EOF
      MCHQC
      runner-mchqc
      agentMCHQC
      MCH
      MCH
      :
      QualityControl
EOF
      ali_echo "Making agent MCHDA"
      ali_amore tmpMCHDA /opt/amore/bin/newAmoreAgent > /dev/null 2>&1 <<EOF
      MCHDA
      runner-mchda
      agentMCHDA
      DB
      MCH
      /data_for_db_agents.raw
      DBPublisher
EOF
      docker-compose down
    }

    ali_echo_color() {

        echo -e "$1$2\033[0m"
    }

    ali_echo_error() {

        ali_echo_color "!!!!!!!!!!!!!!!! \033[0;31m$1"
    }

    ali_echo_strong() {

        ali_echo_color "\033[1;30m$1"
    }

    ali_echo() {

      ali_echo_strong "==================== $1"
      shift
      $@
    }

    ali_exec() {

        ali_echo $1
        shift
        $@
        rc=$?
        if [ $rc -ne 0 ]; then
            ali_echo_error "Command $@ failed with return code $rc"
            docker-compose down
            return 1
        fi
        return 0
    }

    ali_bootstrap() {

      # - create a default mysql DATE database
      # - build/download all the required images
      # - create all data volumes

      # to be able to use any of the docker-compose commands
      # we must first get all the data volumes declared in
      # the docker-compose.yml file created

      ali_exec "Make volumes" ali_make_volumes || return

      ali_exec "Make images" ali_make_images || return

      ali_exec "Make and populate DATE DB" ali_make_datedb || return

      ali_exec "Make and populate AMORE DB" ali_make_amoredb || return

      ali_exec "Make some agents" ali_make_agents || return

      ali_echo "Install some MCH DAs"

      ali_exec "Bringing up date DB" ali_up_datedb || return

      ali_exec "Installing DA MCH-BPEVO" ali_install_da MCH-BPEVO || return
      ali_exec "Installing DA MCH-OCC" ali_install_da MCH-OCC || return
      ali_exec "Installing DA MCH-PED" ali_install_da MCH-PED || return

      ali_exec "Getting docker containers down" docker-compose down || return
    }

    ali_install_da() {
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
