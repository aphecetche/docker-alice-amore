# .bashrc

# User specific aliases and functions

alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# Source global definitions
if [ -f /etc/bashrc ]; then
        . /etc/bashrc
fi

# start at /alicesw if available

if [[ -d /alicesw ]]; then
    cd /alicesw
    eval $(alienv load VO_ALICE@${ALI_WHAT}::latest-${ALI_VERSION})
    aliBuild analytics on
fi


