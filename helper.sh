#!/bin/sh

project=dockeraliceamore

amore() {
    # create an amore container 
    # with the proper links etc...
    # that can be used for the amore (modules) binaries
    local host_name=$1
    drunx11 -it --rm \
        -v vc_date_site:/dateSite \
        -v vc_date_db:/var/lib/mysql \
        -v vc_amore_site:/amoreSite \
        -v vc_daq_fxs:/daqfxs \
        -v $PWD/ssh-user.daq:/home/daq/.ssh \
        -v ${HOME}/alicesw/run2/amore_modules/:/amore_modules \
        -v vc_amore_cdb:/local/cdb \
        --net ${project}_default \
        -e DATE_SITE=/dateSite \
        --hostname=$host_name \
        -v /tmp/deroot:/tmp/deroot \
        -v /etc/localtime:/etc/localtime \
        aphecetche/alice-amore \
        /bin/bash
}


amore_modules_dev() {
    # create an amore container 
    # with the proper links etc...
    # than can be used to compile amore modules
    local host_name=$1
    drunx11 -it --rm \
        -v vc_date_site:/dateSite \
        -v vc_date_db:/var/lib/mysql \
        -v vc_amore_site:/amoreSite \
        -v vc_amore_cdb:/local/cdb \
        -v ${HOME}/alicesw/run2/amore_modules/:/amore_modules \
        -v ${HOME}/.globus:/root/.globus \
        --link ${project}_datedb_1 \
        --link ${project}_dim_1 \
        --link ${project}_infologger_1 \
        --net ${project}_default \
        -e DATE_SITE=/dateSite \
        --hostname=$host_name \
        -v /etc/localtime:/etc/localtime \
        aphecetche/amore-devel \
        /bin/bash
}


amore_dev() {
    # create an amore container 
    # with the proper links etc...
    # than can be used to compile amore modules
    local host_name=$1
    drunx11 -it --rm \
        -v vc_date_site:/dateSite \
        -v vc_date_db:/var/lib/mysql \
        -v vc_amore_site_dev:/amoreSite \
        -v vc_amore_cdb:/local/cdb \
        -v vc_amore_opt:/opt/amore \
        -v ${HOME}/alicesw/run2/amore_modules/:/amore_modules \
        -v ${HOME}/alicesw/run2/amore/:/amore \
        -v ${HOME}/.globus:/root/.globus \
        --link ${project}_datedb_1 \
        --link ${project}_dim_1 \
        --link ${project}_infologger_1 \
        --net ${project}_default \
        -e DATE_SITE=/dateSite \
        --hostname=$host_name \
        -v /etc/localtime:/etc/localtime \
        aphecetche/amore-devel \
        /bin/bash
}

dadev() {
    local detectorcode=${2:="MCH"}
    docker run -it --rm \
        -v $(pwd):/daoutput \
        -v vc_date_site:/dateSite \
        -v vc_date_db:/var/lib/mysql \
        -v vc_amore_site:/amoreSite \
        -v vc_amore_cdb:/local/cdb \
        -v vc_daq_fxs:/daqfxs \
        -v vc_run2_sw:/alicesw/sw \
        -v ${HOME}/.globus:/root/.globus:ro \
        -v ${HOME}/alicesw/run2/aliroot-date/AliRoot:/alicesw/AliRoot:ro \
        -v ${HOME}/alicesw/run2/aliroot-date/ROOT:/alicesw/ROOT:ro \
        -v ${HOME}/alicesw/run2/aliroot-date/alidist:/alicesw/alidist:ro \
        -v ${HOME}/alicesw/repos/AliRoot:$HOME/alicesw/repos/AliRoot:ro \
        --link ${project}_datedb_1 \
        --link ${project}_dim_1 \
        --link ${project}_infologger_1 \
        --net ${project}_default \
        -e DATE_DETECTOR_CODE="$detectorcode" \
        -e DATE_SITE=/dateSite \
        -e DATE_RUN_NUMBER=123 \
        -e DATE_ROLE_NAME=da \
        -e ALI_WHAT=AliRoot \
        -e ALI_VERSION=date \
        -v /etc/localtime:/etc/localtime \
        aphecetche/alice-muon-das-devel \
    /bin/bash
}

callda() {
    local dapath=$1
    local detectorcode=$2
    local rawfile=$3
    docker run -it --rm \
        -v $rawfile:/file.raw \
        -v $(pwd):/daoutput \
        -v vc_date_site:/dateSite \
        -v vc_date_db:/var/lib/mysql \
        -v vc_amore_site:/amoreSite \
        -v vc_amore_cdb:/local/cdb \
        -v vc_daq_fxs:/daqfxs \
        --link ${project}_datedb_1 \
        --link ${project}_dim_1 \
        --link ${project}_infologger_1 \
        --net ${project}_default \
        -e DATE_DETECTOR_CODE="$detectorcode" \
        -e DATE_SITE=/dateSite \
        -e DATE_RUN_NUMBER=123 \
        -e DATE_ROLE_NAME=da \
        aphecetche/alice-muon-das \
        $dapath /file.raw 
}

damchbpevo() {
    local rawfile=$1
    callda /opt/daqDA-MCH-BPEVO/MCHBPEVOda.exe MCH $rawfile
}

infoBrowser() {
    # create an amore container 
    # with the proper links etc...
    # to run the infobrowser 
    drunx11 -it --rm \
        -v vc_date_site:/dateSite \
        -v vc_date_db:/var/lib/mysql \
        --net ${project}_default \
        -e DATE_SITE=/dateSite \
        -v /etc/localtime:/etc/localtime \
        aphecetche/alice-date \
       /launch_infoBrowser.sh 
}

amoreGui() {
    # create an amore container 
    # with the proper links etc...
    # to run amoreGui

    drunx11 --rm \
        -v vc_date_site:/dateSite \
        -v vc_date_db:/var/lib/mysql \
        -v vc_amore_site:/amoreSite \
        -v $PWD/ssh-user.daq:/home/daq/.ssh \
        -v vc_amore_cdb:/local/cdb \
        --net ${project}_default \
        -e DATE_SITE=/dateSite \
        -v /etc/localtime:/etc/localtime \
        aphecetche/alice-amore \
       /launch_amoreGui.sh 
}

