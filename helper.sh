project=dockeramore

amore() {
    # create an amore container 
    # with the proper links etc...
    drunx11 -it --rm \
        -v vc_date_site:/dateSite \
        -v vc_date_db:/var/lib/mysql \
        -v vc_amore_site:/amoreSite \
        --link ${project}_datedb_1 \
        --link ${project}_dim_1 \
        --link ${project}_infologger_1 \
        --net ${project}_default \
        -e DATE_SITE=/dateSite \
        aphecetche/alice-amore \
        /bin/bash
}

