#!/usr/bin/env bash
# *********************************************************************
# *
# * This program is free software; you can redistribute it and/or
# * modify it. It is distributed in the hope that it will be useful,
# * but WITHOUT ANY WARRANTY; without even the implied warranty of
# * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# *
# *********************************************************************

# ******************************
# * Setup -- Functions section *
# ******************************

# Colors as per: http://www.tldp.org/LDP/abs/html/colorizing.html

echoerrcolor() {
	if [[ $colors -eq 1 ]]; then
		case $1 in
		green)
			str='\e[0;32m'
			;;
		red)
			str='\e[0;31m'
			;;
		blue)
			str='\e[1;34m'
			;;
		darkcyan)
			str='\e[0;36m'
			;;
		darkgreen)
			str='\e[1;32m'
			;;
		darkred)
			str='\e[1;31m'
			;;
		magenta)
			str='\e[0;35m'
			;;
		darkmagenta)
			str='\e[1;35m'
			;;
		*)
			str='\e[0;37m'
			;;
		esac
		echo -ne "${str}" >&2
	fi
}

echoerrnocolor() {
	if [[ ${colors} -eq 1 ]]; then
		echo -ne '\e[0m' >&2
	fi
}

# TODO: Consolidate all output into a single function with conditional color support
printline() {
	if [[ $# -gt 1 ]]; then
		color=$1
		shift
		echoerrcolor "${color}"
	fi
	echo "$@" >&2
	if [[ $color ]]; then
		echoerrnocolor
	fi
}

printout() { printf "%s\n" "$@" >&2; }

# https://www.shellcheck.net/wiki/SC2091
if [[ ! $(which git) ]]; then
	# shellcheck disable=SC2016
	printline red 'git command Not found (in PATH)! Confirm it is indeed installed and in $PATH.'
	exit
fi

appendshell() {
	case "${1}" in
	start)
		add='echo "Setting up Dotbot. Please do not ^C." >&2;'
		;;
	mktarget)
		add="mkdir -p ${2}; cd ${2};"
		;;
	gitinit)
		add='git init;'
		;;
	gitaddsub)
		add='git submodule add https://github.com/anishathalye/dotbot;'
		;;
	gitignoredirty)
		add='git config -f .gitmodules submodule.dotbot.ignore dirty;'
		;;
	gitinstallinstall)
		add='cp dotbot/tools/git-submodule/install .;'
		;;
	ensureparentdirs)
		add="mkdir -p ${2}; rmdir ${2};"
		;;
	mv)
		add="mv ${2} ${3};"
		;;
	runinstaller)
		add='./install;'
		;;
	gitsetname)
		if (($3)); then
			global=' --global '
		else
			global=' '
		fi
		add='git config'$global'user.name "'${2}'";'
		;;
	gitsetemail)
		if (($3)); then
			global=' --global '
		else
			global=' '
		fi
		add='git config'$global'user.email "'${2}'";'
		;;
	gitinitialcommit)
		add='git add -A; git commit -m "Initial commit";'
		;;

	esac
	# append $add to $setupshell, on a new line
	setupshell="${setupshell}
${add}"
}

# ******************************
# * Setup -- Variables section *
# ******************************

# Declare variables and set defaults
# TODO: make colors-enabled the default mode, once its working properly
colors=0
dotclean=''
dotlink=''
dotshell=''
dumpconf=0
installerrun=1
preview=1
setupshell=''
testmode=0
verboseconf=0
MODETEXT='    ____      _ __     ____        __  _____ __
   /  _/___  (_) /_   / __ \____  / /_/ __(_) /__  _____
   / // __ \/ / __/  / / / / __ \/ __/ /_/ / / _ \/ ___/
 _/ // / / / / /_   / /_/ / /_/ / /_/ __/ / /  __(__  )
/___/_/ /_/_/\__/  /_____/\____/\__/_/ /_/_/\___/____/
'

# *******************************
# * Setup -- Parameters section *
# *******************************


while [[ $# -ne 0 ]]; do
	case "${1}" in
	test)
		testmode=1
		installerrun=0
		printline darkcyan "Test mode enabled."
		;;
	no-test)
		testmode=0
		printline darkcyan "Test mode disabled."
		;;
	verbose-config)
		verboseconf=1
		printline darkcyan "Verbose configuration file active."
		;;
	no-verbose-config)
		verboseconf=0
		printline darkcyan "Concise configuration file active."
		;;
	dump-config)
		dumpconf=1
		printline darkcyan "Will dump config to stdout."
		;;
	no-dump-config)
		dumpconf=0
		printline darkcyan "Will not dump config to stdout."
		;;
	preview)
		preview=1
		printline darkcyan "Will show commands to be executed."
		;;
	no-preview)
		preview=0
		printline darkcyan "Will not show commands to be executed."
		;;
	colors)
		colors=1
		printline darkcyan "Will print with colors."
		;;
	no-colors)
		colors=0
		printline darkcyan "No color."
		;;
	*)
		printline red "${hspace}Ignoring unrecognized parameter / configuration option: ${1}"
		;;
	esac
	shift
done

# shellcheck disable=SC2088
paths=('~/.profile'
	'~/.bash_profile'
	'~/.bashrc'
	'~/.bash_logout'
	'~/.bash_aliases'
	'~/.conkyrc'
	'~/.gitconfig'
	'~/.ssh/config'
	'~/.tmux.conf'
	'~/.vimrc'
	'~/.vim/vimrc'
	'~/.zprofile'
	'~/.zshenv'
	'~/.zshrc'
	'~/bin'
	'~/.Xmodmap'
	'~/.Xresources'
	'~/.Xdefaults'
	'~/.vimperatorrc'
	'~/.xinitrc'
	'~/.i3'
	'~/.i3status.conf'
	'~/.config/awesome'
	'~/.config/i3'
	'~/.config/pianobar'
	'~/.config/vimprobable'
	'~/.config/redshift'
	'~/.config/openbox'
	'~/.config/obmenu-generator'
	'~/.config/dmenu'
	'~/.config/tint2')

# Set constants
dotlink='- link:'
# Use ANSI-C Quoting to render whitespace
# https://www.gnu.org/software/bash/manual/html_node/ANSI_002dC-Quoting.html
newline=$'\n'
hspace=$'\x20\x20\x20\x20'

# ************************************
# * Start of Logic / Process section *
# ************************************
printline
printline blue "Configuration generator for Dotbot"
printline blue "At any time, press ^C to quit. No changes will be made until you confirm."
printline

appendshell start

# shellcheck disable=SC2088
target="~/.dotfiles"

if [[ ! -d "${target/\~/${HOME}}" ]]; then
	printline darkcyan "${target} is not in use."
else
	printline darkcyan "${target} exists and may have another purpose than ours."
fi

while true; do
	read -r -p "Confirm path to your dotfiles repository: (${target})" answer
	if [[ -z "${answer}" ]]; then
		break
	else
		printline red "FEATURE NOT YET SUPPORTED."
		printline red "Sorry for misleading you."
		printline
	fi
done

appendshell mktarget "${target}"
appendshell gitinit

while true; do
	read -r -p "(Recommended) Add the Dotbot repo as a submodule? (Y/n)" answer
	if [[ -z "${answer}" ]]; then
		answer='y'
	fi
	case "${answer}" in
	Y* | y*)
		printline green "${hspace}OK: will do."
		appendshell gitaddsub
		appendshell gitignoredirty
		appendshell gitinstallinstall
		break
		;;
	N* | n*)
		printline darkgreen "${hspace}OK: will not." # You will need to manually modify your Dotbot ./install script."
		installerrun=0
		break
		;;
	*)
		printline red "${hspace}Error: Unrecognized answer: ${answer}"
		;;
	esac
done

while true; do
	read -r -p '(Recommended) Clean $HOME of any broken links? (Y/n)' answer
	if [[ -z "$answer" ]]; then
		answer='y'
	fi
	case "$answer" in
	Y* | y*)
		printline green "OK: Dotbot will clean links in \$HOME."
		dotclean="- clean: ['~']"
		break
		;;
	N* | n*)
		printline darkgreen "Dotbot will Not clean links."
		break
		;;
	*)
		printline red "Error: Unrecognized answer: ${answer}"
		;;
	esac
done

declare -a linksection
declare -i i

# shellcheck disable=SC2048
for item in ${paths[*]}; do
	fullname="${item/\~/$HOME}"
	if [[ -L "${fullname}" ]]; then
		continue
	fi
	if [[ -f "${fullname}" ]] || [[ -d "${fullname}" ]]; then
		while true; do
			read -r -p "${item}: [Enter] to confirm management should be migrated to Dotbot, or type 'n' first to bypass it. (Y/n)" answer
			if [[ -z "${answer}" ]]; then
				answer='y'
			fi
			case "${answer}" in
			Y* | y*)
				linksection[${i}]=${item}
				i=${i}+1
				printline green "${hspace}OK: Dotbotted!"
				break
				;;
			N* | n*)
				printline darkgreen "${hspace}OK: Not Dotbotted."
				break
				;;
			*)
				printline red "${hspace}Error: Unrecognized answer: ${answer}"
				;;
			esac
		done
	fi
done

# shellcheck disable=SC2048
for item in ${linksection[*]}; do
	fullname="${item/\~/$HOME}"
	firstdot=$(echo "${item}" | sed -n "s/[.].*//p" | wc -c)
	firstslash=$(echo "${item}" | sed -n "s/[/].*//p" | wc -c)
	if [[ -d "${fullname}" ]]; then
		itempath="${item}/"
	else
		itempath="${item}"
	fi
	if [[ ${firstdot} -gt ${firstslash} ]]; then
		itempath="${itempath:${firstdot}}"
	else
		itempath="${itempath:${firstslash}}"
	fi
	nextslash=$(echo "${itempath}" | sed -n "s/[/].*//p" | wc -c)
	if [[ ${nextslash} -gt 0 ]]; then
		entryisdir='true'
	else
		entryisdir='false'
	fi
	if [[ ${verboseconf} -eq 1 ]]; then
		new_entry="${newline}${hspace}${item/$HOME/\$HOME}:"
		new_entry="${new_entry}${newline}${hspace}${hspace}path: ${itempath}"
		new_entry="${new_entry}${newline}${hspace}${hspace}create: ${entryisdir}"
		new_entry="${new_entry}${newline}${hspace}${hspace}relink: false"
		new_entry="${new_entry}${newline}${hspace}${hspace}force: false"
	elif [[ $entryisdir = 'false' ]]; then
		new_entry="${newline}${hspace}${item/$HOME/\$HOME}: ${itempath}"
	else
		new_entry="${newline}${hspace}${item/$HOME/\$HOME}:"
		new_entry="${new_entry}${newline}${hspace}${hspace}path: ${itempath}"
		new_entry="${new_entry}${newline}${hspace}${hspace}create: ${entryisdir}"
	fi

	# TODO Accelerate; we should only have to do this 1 time per basedir, such as $HOME
	appendshell ensureparentdirs "${itempath}"
	appendshell mv "${item}" "${itempath}"
	dotlink="${dotlink}${new_entry}"
done

installconfyaml="${dotclean}
${dotlink}
${dotshell}"
export installconfyaml

# Write the dotbot config file -- this should stand out in the terminal UI \
# especially if there are many dotfiles or dotdirs that have just been \
# prompted and clicked through.
printline
printline yellow '! Congratulations! That is the end of the Dotbot survey'
# TODO: The name of this output file should be configurable
printline green 'Writing dotbot config to install.conf.yaml'
printline
printf '%s' "${installconfyaml}" > 'install.conf.yaml'

getgitinfo=0
gitinfoglobal=0
if [[ ${installerrun} -eq 1 ]]; then

	if [[ -z $(git config user.name) || -z $(git config user.email) ]]; then
		printline darkred "${hspace}~/.gitconfig is missing name and/or email."
		# printline darkred "${hspace}You will not be able to commit any updates until you configure git."
		while true; do
			read -r -p "Do you want to set them now? (Y/n)" answer
			if [[ -z "${answer}" ]]; then
				answer='y'
			fi
			case "${answer}" in
			Y* | y*)
				getgitinfo=1
				break
				;;
			N* | n*)
				printline darkgreen "${hspace}OK: will not."
				getgitinfo=0
				installerrun=0
				break
				;;
			*)
				printline red "${hspace}Error: Unrecognized answer: ${answer}"
				;;
			esac
		done
		while true; do
			read -r -p "Do you want these settings to be global? (Y/n)" answer
			if [[ -z "${answer}" ]]; then
				answer='y'
			fi
			case "${answer}" in
			Y* | y*)
				printline green "Adding --global to the set commands."
				gitinfoglobal=1
				break
				;;
			N* | n*)
				printline green "OK: will make them local."
				gitinfoglobal=0
				break
				;;
			*)
				printline red "${hspace}Error: Unrecognized answer: ${answer}"
				;;
			esac
		done
	fi
fi
if [[ ${getgitinfo} -eq 1 ]]; then
	if [[ -z $(git config user.name) ]]; then
		gitname="Donald Knuth"
	else
		gitname="$(git config user.name)"
	fi
	if [[ -z $(git config user.email) ]]; then
		gitemail="Don.Knuth@example.com"
	else
		gitemail="$(git config user.email)"
	fi
	read -r -p "What do you want for your git name? [${gitname}]" answer
	if [[ -z "${answer}" ]]; then
		answer="${gitname}"
	fi
	gitname="${answer}"
	read -r -p "What do you want for your git email? [${gitemail}]" answer
	if [[ -z "${answer}" ]]; then
		answer="${gitemail}"
	fi
	gitemail="${answer}"
	appendshell gitsetname "${gitname}" "${gitinfoglobal}"
	appendshell gitsetemail "${gitemail}" "${gitinfoglobal}"
fi

while [[ $installerrun -eq 1 ]]; do
	read -r -p "Run the installer? (Necessary to git commit) (Y/n)" answer
	if [[ -z "${answer}" ]]; then
		answer='y'
	fi
	case "${answer}" in
	Y* | y*)
		printline green "${hspace}OK: Will do."
		appendshell runinstaller
		break
		;;
	N* | n*)
		printline darkgreen "${hspace}OK: will not. You will need to take care of that yourself."
		installerrun=0
		break
		;;
	*)
		printline red "${hspace}Error: Unrecognized answer: ${answer}. Please try again."
		;;
	esac
done

while [[ $installerrun -eq 1 ]]; do
	read -r -p "Make the initial commit? (Y/n)" answer
	if [[ -z "${answer}" ]]; then
		answer='y'
	fi
	case "${answer}" in
	Y* | y*)
		printline green "${hspace}OK: Will do."
		appendshell gitinitialcommit
		break
		;;
	N* | n*)
		printline darkgreen "${hspace}OK: will not. You will need to take care of that yourself."
		break
		;;
	*)
		printline red "${hspace}Error: Unrecognized answer: ${answer}. Please try again."
		;;
	esac
done

printline
if [[ ${dumpconf} -eq 1 ]]; then
	echo -e "${dotlink}"
	printline
fi
printline magenta "The below are the actions that will be taken to setup Dotbot."
if [[ "${testmode}" -eq 1 ]]; then
	printline darkmagenta "Just kidding. They won't be."
fi

if [[ "${preview}" -eq 1 ]]; then
	# TODO: Write setupshell to a file and print/cat the file
	# Call "setupshell" comething like ./migrate-dotfiles.sh
	printout "${setupshell}"
	warningmessage='If you are ready to make these changes to your files, press [Enter] to proceed.'
else
	warningmessage=''
fi

# TODO Update Test mode behavior so that `appendshell` \
# writes the dotbot config file, but doesn't yet change any files or dirs

echoerrcolor darkred
# TODO Make this "final pre-flight check" message more dynamic;
# applicable to test/preview mode, dump-config
# Should be able to just expand usage of ${warningmessage}
read -r -p "${warningmessage}
This is your last chance to press ^C before actions are taken that should not be interrupted."
echoerrnocolor

if [[ $testmode -eq 0 ]]; then
	eval "${setupshell}"
fi
