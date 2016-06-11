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
        -v ${HOME}/alicesw/run2/amoreMCH:/amoreMCH \
        --link ${project}_datedb_1 \
        --link ${project}_dim_1 \
        --link ${project}_infologger_1 \
        --net ${project}_default \
        -e DATE_SITE=/dateSite \
        --hostname=$host_name \
        -v /tmp/deroot:/tmp/deroot \
        aphecetche/alice-amore \
        /bin/bash
}

amoredev() {
    # create an amore container 
    # with the proper links etc...
    # than can be used to compile amore modules
    local host_name=$1
    drunx11 -it --rm \
        -v vc_date_site:/dateSite \
        -v vc_date_db:/var/lib/mysql \
        -v vc_amore_site:/amoreSite \
        -v vc_amore_cdb:/local/cdb \
        -v ${HOME}/alicesw/run2/amoreMCH:/amoreMCH \
        -v ${HOME}/alicesw/run2/amoreQA:/amoreQA \
        -v ${HOME}/.globus:/root/.globus \
        --link ${project}_datedb_1 \
        --link ${project}_dim_1 \
        --link ${project}_infologger_1 \
        --net ${project}_default \
        -e DATE_SITE=/dateSite \
        --hostname=$host_name \
        amore-devel \
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

