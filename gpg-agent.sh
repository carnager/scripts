#!/bin/bash
#----------------------------------------------------
# Author:       Florian "Bluewind" Pritz <flo@xssn.at>
#
# Licensed under WTFPL v2
#   (see COPYING for full license text)
#
#----------------------------------------------------
# make working with the agent easier and prevent
# starting multiple agents
#----------------------------------------------------
initgpg(){
	[[ -z $XDG_CONFIG_HOME ]] && XDG_CONFIG_HOME="$HOME/.config"
	[[ -z $XDG_DATA_HOME ]] && XDG_DATA_HOME="$HOME/.local/share"
	[ -f "$XDG_CONFIG_HOME/disable-gpg-agent" ] && return 0
	envfile="${XDG_DATA_HOME}/.gpginfo"
	if test -f ${envfile} && test -S $(cut -d= -f 2 ${envfile} | head -n 2 | tail -n 1) 2>/dev/null; then
		. ${envfile}
	else
		/usr/bin/gpg-agent --daemon --enable-ssh-support --write-env-file ${envfile}
		. ${envfile}
	fi
	export GPG_AGENT_INFO
	export SSH_AUTH_SOCK
	export SSH_AGENT_PID
}
if [[ -n $DISPLAY ]]; then
	initgpg
fi
