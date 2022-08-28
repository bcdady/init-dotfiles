#!/usr/bin/env bash

# Colors as per: http://www.tldp.org/LDP/abs/html/colorizing.html

echoerrcolor() {
	if [[ $colors -eq 1 ]]; then
		case $1 in
		green)
			str="\e[0;32m"
			;;
		red)
			str="\e[0;31m"
			;;
		blue)
			str="\e[1;34m"
			;;
		darkcyan)
			str="\e[0;36m"
			;;
		darkgreen)
			str="\e[1;32m"
			;;
		darkred)
			str="\e[1;31m"
			;;
		magenta)
			str="\e[0;35m"
			;;
		darkmagenta)
			str="\e[1;35m"
			;;
		*)
			str="\e[0;37m"
			;;
		esac
		echo -ne "$str" >&2
	fi
}

echoerrnocolor() {
	if [[ $colors -eq 1 ]]; then
		echo -ne "\e[0m" >&2
	fi
}

echoerr() {
	if [[ $# -gt 1 ]]; then
		color=$1
		shift
		echoerrcolor "$color"
	fi
	echo "$@" >&2
	if [[ $color ]]; then
		echoerrnocolor
	fi
}

printout() { printf "%s\n" "$@" >&2; }

# https://www.shellcheck.net/wiki/SC2091
if ! which git; then
	# shellcheck disable=SC2016
	echoerr red 'git command Not found (in PATH)! Confirm it is indeed installed and in $PATH.'
	exit
fi

appendshell() {
	case "$1" in
	start)
		add='echo "Setting up Dotbot. Please do not ^C." >&2;'
		;;
	mkprefix)
		add="mkdir -p $2; cd $2;"
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
		add="mkdir -p $2; rmdir $2;"
		;;
	mv)
		add="mv $2 $3;"
		;;
	echoconfig)
		add='echo -e "'$2'" >> '$3';'
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
		add='git config'$global'user.name "'$2'";'
		;;
	gitsetemail)
		if (($3)); then
			global=' --global '
		else
			global=' '
		fi
		add='git config'$global'user.email "'$2'";'
		;;
	gitinitialcommit)
		add='git add -A; git commit -m "Initial commit";'
		;;

	esac
	# append $add to $setupshell, on a new line
	setupshell="${setupshell}
${add}"
}

testmode=0
verboseconf=0
dumpconf=0
preview=1
colors=0

while [[ $# -ne 0 ]]; do
	case "$1" in
	test)
		testmode=1
		echoerr darkcyan "Test mode enabled."
		;;
	no-test)
		testmode=0
		echoerr darkcyan "Test mode disabled."
		;;
	verbose-config)
		verboseconf=1
		echoerr darkcyan "Verbose configuration file active."
		;;
	no-verbose-config)
		verboseconf=0
		echoerr darkcyan "Concise configuration file active."
		;;
	dump-config)
		dumpconf=1
		echoerr darkcyan "Will dump config to stdout."
		;;
	no-dump-config)
		dumpconf=0
		echoerr darkcyan "Will not dump config to stdout."
		;;
	preview)
		preview=1
		echoerr darkcyan "Will show commands to be executed."
		;;
	no-preview)
		preview=0
		echoerr darkcyan "Will not show commands to be executed."
		;;
	colors)
		colors=1
		echoerr darkcyan "Will print with colors."
		;;
	no-colors)
		colors=0
		echoerr darkcyan "No color."
		;;
	*)
		echoerr red "Unfamiliar configuration option"
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

setupshell=''
dotclean=''
dotlink=''
dotshell=''
installerrun=1

echoerr blue "Welcome to the configuration generator for Dotbot"
echoerr blue "Please be aware that if you have a complicated setup, you may need more customization than this script offers."
echoerr
echoerr blue "At any time, press ^C to quit. No changes will be made until you confirm."
echoerr

appendshell start

# shellcheck disable=SC2088
prefix="~/.dotfiles"

if ! [[ -d "${prefix/\~/${HOME}}" ]]; then
	echoerr darkcyan "${prefix} is not in use."
else
	echoerr darkcyan "${prefix} exists and may have another purpose than ours."
fi

while true; do
	read -r -p "Where do you want your dotfiles repository to be? ($prefix) " answer
	if [[ -z "$answer" ]]; then
		break
	else
		echoerr red "FEATURE NOT YET SUPPORTED."
		echoerr red "Sorry for misleading you."
		echoerr
	fi
done

appendshell mkprefix "${prefix}"
appendshell gitinit

while true; do
	read -r -p "Shall we add Dotbot as a submodule (a good idea)? (Y/n) " answer
	if [[ -z "$answer" ]]; then
		answer='y'
	fi
	case "$answer" in
	Y* | y*)
		echoerr green "Will do."
		appendshell gitaddsub
		appendshell gitignoredirty
		appendshell gitinstallinstall
		break
		;;
	N* | n*)
		echoerr darkgreen "Okay: will not. You will need to manually set up your install script."
		installerrun=0
		break
		;;
	*)
		echoerr red "Error: Unrecognized answer: ${answer}"
		;;
	esac
done

while true; do
	read -r -p "Do you want Dotbot to clean ~/ of broken links added by Dotbot? (recommended) (Y/n) " answer
	if [[ -z "$answer" ]]; then
		answer='y'
	fi
	case "$answer" in
	Y* | y*)
		echoerr green "I will ask Dotbot to clean."
		dotclean="- clean: ['~']"
		break
		;;
	N* | n*)
		echoerr darkgreen "Not asking Dotbot to clean."
		break
		;;
	*)
		echoerr red "Error: Unrecognized answer: ${answer}"
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
			read -r -p "I found ${item}, do you want to Dotbot it? (Y/n) " answer
			if [[ -z "$answer" ]]; then
				answer='y'
			fi
			case "$answer" in
			Y* | y*)
				linksection[$i]=$item
				i=$i+1
				echoerr green "Dotbotted!"
				break
				;;
			N* | n*)
				echoerr darkgreen "Not added to Dotbot."
				break
				;;
			*)
				echoerr red "Error: Unrecognized answer: ${answer}"
				;;
			esac
		done
	fi
done

dotlink='- link:'
hspace='\x20\x20\x20\x20'

# shellcheck disable=SC2048
for item in ${linksection[*]}; do
	fullname="${item/\~/$HOME}"
	firstdot=$(echo "$item" | sed -n "s/[.].*//p" | wc -c)
	firstslash=$(echo "$item" | sed -n "s/[/].*//p" | wc -c)
	if [[ -d "${fullname}" ]]; then
		itempath=$item'/'
	else
		itempath=$item
	fi
	if [[ $firstdot -gt $firstslash ]]; then
		itempath=${itempath:$firstdot}
	else
		itempath=${itempath:$firstslash}
	fi
	nextslash=$(echo "$itempath" | sed -n "s/[/].*//p" | wc -c)
	if [[ $nextslash -gt 0 ]]; then
		entryisdir='true'
	else
		entryisdir='false'
	fi
	if [[ $verboseconf -eq 1 ]]; then
		new_entry=$newline$hspace$item':'
		new_entry=$new_entry$newline$hspace$hspace'path: '$itempath
		new_entry=$new_entry$newline$hspace$hspace'create: '$entryisdir
		new_entry=$new_entry$newline$hspace$hspace'relink: false'
		new_entry=$new_entry$newline$hspace$hspace'force: false'
	elif [[ $entryisdir = 'false' ]]; then
		new_entry=$newline$hspace$item': '$itempath
	else
		new_entry=$newline$hspace$item':'
		new_entry=$new_entry$newline$hspace$hspace'path: '$itempath
		new_entry=$new_entry$newline$hspace$hspace'create: '$entryisdir
	fi

	# TODO Accelerate; we should only have to do this 1 time per basedir, such as $HOME
	appendshell ensureparentdirs "$itempath"
	# TODO Update Test mode behavior so that `appendshell` \
	# writes the file, but doesn't yet change any files or dirs
	appendshell mv "$item" "$itempath"
	dotlink="$dotlink$new_entry"
done

installconfyaml="$dotclean
$dotlink
$dotshell"
export installconfyaml

# Write the dotbot config file
# TODO: The name of this output file should be configurable
echoerr green 'Writing dotbot config to install.conf.yaml' 
printf '%s' "${installconfyaml}" > 'install.conf.yaml'

getgitinfo=0
gitinfoglobal=0
if [[ $installerrun -eq 1 ]]; then

	if [[ -z $(git config user.name) || -z $(git config user.email) ]]; then
		echoerr darkred "Please note you do not have a name or email set for git."
		echoerr darkred "You will not be able to commit any updates until you configure git."
		while true;  do
			read -r -p "Do you want to set them? (Y/n) " answer
			if [[ -z "$answer" ]]; then
				answer='y'
			fi
			case "$answer" in
			Y* | y*)
				getgitinfo=1
				break
				;;
			N* | n*)
				echoerr darkgreen "Okay: will not."
				getgitinfo=0
				installerrun=0
				break
				;;
			*)
				echoerr red "Error: Unrecognized answer: ${answer}"
				;;
			esac
		done
		while true; do
			read -r -p "Do you want these settings to be global? (Y/n) " answer
			if [[ -z "$answer" ]]; then
				answer='y'
			fi
			case "$answer" in
			Y* | y*)
				echoerr green "Adding --global to the set commands."
				gitinfoglobal=1
				break
				;;
			N* | n*)
				echoerr green "Okay: will make them local."
				gitinfoglobal=0
				break
				;;
			*)
				echoerr red "Error: Unrecognized answer: ${answer}"
				;;
			esac
		done
	fi
fi
if [[ $getgitinfo -eq 1 ]]; then
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
	if [[ -z "$answer" ]]; then
		answer="$gitname"
	fi
	gitname="$answer"
	read -r -p "What do you want for your git email? [${gitemail}]" answer
	if [[ -z "$answer" ]]; then
		answer="$gitemail"
	fi
	gitemail="$answer"
	appendshell gitsetname "$gitname" $gitinfoglobal
	appendshell gitsetemail "$gitemail" $gitinfoglobal
fi

while [[ $installerrun -eq 1 ]]; do
	read -r -p "Run the installer? (Necessary to git commit) (Y/n) " answer
	if [[ -z "$answer" ]]; then
		answer='y'
	fi
	case "$answer" in
	Y* | y*)
		echoerr green "Will do."
		appendshell runinstaller
		break
		;;
	N* | n*)
		echoerr darkgreen "Okay: will not. You will need to take care of that yourself."
		installerrun=0
		break
		;;
	*)
		echoerr red "Error: Unrecognized answer: ${answer}"
		;;
	esac
done

while [[ $installerrun -eq 1 ]]; do
	read -r -p "Make the initial commit? (Y/n) " answer
	if [[ -z "$answer" ]]; then
		answer='y'
	fi
	case "$answer" in
	Y* | y*)
		echoerr green "Will do."
		appendshell gitinitialcommit
		break
		;;
	N* | n*)
		echoerr darkgreen "Okay: will not. You will need to take care of that yourself."
		break
		;;
	*)
		echoerr red "Error: Unrecognized answer: ${answer}"
		;;
	esac
done

echoerr
if [[ $dumpconf -eq 1 ]]; then
	echo -e "$dotlink"
	echoerr
fi
echoerr magenta "The below are the actions that will be taken to setup Dotbot."
if [[ $testmode -eq 1 ]]; then
	echoerr darkmagenta "Just kidding. They won't be."
fi

if [[ $preview -eq 1 ]]; then
	printout "${setupshell}"
	warningmessage='If you do not see a problem with the above commands, press enter.'
else
	warningmessage=''
fi

echoerrcolor darkred
# TODO Make this "final pre-flight check" message more dynamic;
# applicable to test/preview mode, dump-config
# Should be able to just expand usage of ${warningmessage}
read -r -p "${warningmessage}This is your last chance to press ^C before actions are taken that should not be interrupted. "
echoerrnocolor

if [[ $testmode -eq 0 ]]; then
	# TODO: write the dotbot YAML file, but don't invoke / eval it
	eval "${setupshell}"
fi
