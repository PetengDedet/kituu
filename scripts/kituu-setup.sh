#!/bin/bash

# Vars
shopt -s dotglob
REPODIR=~/.kituu
LISPDIR=~/.emacs.d/elisp
SCRIPTDIR=~/bin
AUTOSTART_DIR=~/.config/autostart

SEP="\n################# "
RW=false
type -P apt-get &>/dev/null || { debian=true >&2; }

if [[ $HOSTNAME == "N900" || $HOSTNAME == "RM696" ]] ; then
    FANCY_ARGS=""
    SYMLINK_MSG=""
else
    FANCY_ARGS="-v"
    SYMLINK_MSG="(symlink)"
fi

[[ $1 = "-rw" ]] && RW=true
[[ ! -d "$SCRIPTDIR" ]] && mkdir $FANCY_ARGS -p $SCRIPTDIR

if ($RW); then vc_prefix="git@github.com:" && message="RW mode ON" && git config --global user.name "xaccrocheur" && git config --global user.email xaccrocheur@gmail.com ; else vc_prefix="https://github.com/" && message="RW mode OFF"; fi

# Packages
declare -A pack
pack[dev_tools]="build-essential texinfo libtool"
pack[dev_clojure]="leiningen openjdk-7-jre"
pack[dev_python]="python-pip python-scipy"
pack[base_utils]="unison baobab gparted virtualbox"
pack[view&players]="smplayer"
pack[image_tools]="gimp inkscape blender libav-tools"
pack[music_prod]="qtractor invada-studio-plugins-lv2 ir.lv2 lv2fil mda-lv2 lv2vocoder so-synth-lv2 swh-lv2 vmpk qmidinet calf-plugins nekobee fluidsynth-dssi hexter swami qarecord lingot"
pack[games]="extremetuxracer supertuxkart stuntrally xonotic"
pack[emacs24_stable]="emacs24 emacs24-el emacs24-common-non-dfsg aspell-fr"
pack[emacs24_snapshot]="snapshot-el emacs-snapshot-gtk emacs-snapshot aspell-fr"
pack[calf_plugins_git_tools]="libtool autoconf libexpat1-dev libfftw3-dev libglib2.0-dev libfluidsynth-dev jackd1 lv2core libglade2-dev gtk2-engines-pixbuf"

BASICS="python zsh vim byobu apt-file curl wget htop bc locate sshfs git subversion cowsay fortune fortunes-off zenity vinagre x11vnc ccze nmap sox p7zip-full links gajim unison nautilus-dropbox xclip"

# icedtea-7-plugin

# MOZilla addons
MOZURL="https://addons.mozilla.org/firefox/downloads/latest"
declare -A MOZ
MOZ[Uppity]="$MOZURL/869/addon-869-latest.xpi"
MOZ[back_is_close]="$MOZURL/939/addon-939-latest.xpi"
MOZ[Firebug]="$MOZURL/1843/addon-1843-latest.xpi"
MOZ[GreaseMonkey]="$MOZURL/748/addon-748-latest.xpi"
MOZ[GreaseMonkey_px_fix]="https://raw.github.com/xaccrocheur/kituu/master/scripts/gm-sane_inputs.user.js"
MOZ[French_dictionary_(save-as_for_thunderbird)]="$MOZURL/354872/addon-354872-latest.xpi"
MOZ[tabmix+]="$MOZURL/1122/addon-1122-latest.xpi"
MOZ[Video_DownloadHelper]="$MOZURL/3006/addon-3006-latest.xpi"
MOZ[adblock_edge]="$MOZURL/394968/platform:2/addon-394968-latest.xpi?src=dp-btn-primary"
MOZ[color_picker]="$MOZURL/271/addon-271-latest.xpi"
MOZ[TabCloser]="$MOZURL/9669/addon-9669-latest.xpi"
MOZ[Ctrl-Tab]="$MOZURL/5244/addon-5244-latest.xpi"
MOZ[TabCloser]="$MOZURL/5244/addon-9369-latest.xpi"
MOZ[GreaseMonkey_jira]="https://raw.github.com/xaccrocheur/kituu/master/scripts/gm-jira.user.js"
MOZ[Smart_Referer]="$MOZURL/327417/addon-327417-latest.xpi"
MOZ[https_everywhere]="https://www.eff.org/https-everywhere"

# Lisp packages
declare -A LISP
LISP[mail-bug]="git clone ${vc_prefix}xaccrocheur/mail-bug.git"
LISP[appt-bug]="git clone ${vc_prefix}xaccrocheur/appt-bug.git"
LISP[pixilang-mode]="git clone ${vc_prefix}xaccrocheur/pixilang-mode.git"
# LISP[nxhtml]="bzr branch lp:nxhtml"

# Various repos (that go in $SCRIPTDIR)
declare -A VARIOUS
VARIOUS[beatnitpicker]="git clone ${vc_prefix}xaccrocheur/beatnitpicker.git"
VARIOUS[leecher]="git clone ${vc_prefix}xaccrocheur/leecher.git"
VARIOUS[regard]="git clone ${vc_prefix}xaccrocheur/regard.git"
# VARIOUS[git-sync]="git clone https://github.com/simonthum/git-sync"

echo -e $SEP"Kituu! #################

$message

Welcome to Kituu, $(whoami). This script allows you to install and maintain various packages from misc places. And well, do what you want done on every machine you install, and are tired of doing over and over again (tiny pedestrian things like create a "tmp" dir in your $HOME).
You will be asked for every package (or group of packages in the case of binaries) if you want to install it ; After that you can run $(basename $0) again (it's in your PATH now if you use the dotfiles, specifically the .*shrc) to update the packages. Sounds good? Let's go."

echo -e $SEP"Dotfiles and scripts"
read -e -p "#### Install / update dotfiles (in $HOME) and scripts (in $SCRIPTDIR)? [Y/n] " YN
if [[ $YN == "y" || $YN == "Y" || $YN == "" ]] ; then
    if [ ! -d $REPODIR ] ; then
	cd && git clone ${vc_prefix}xaccrocheur/kituu.git
    else
	cd $REPODIR && git pull
    fi

    for i in * ; do
	if [[  ! -h ~/$i && $i != *#* && $i != *~* && $i != *git* && $i != "README.org" && $i != "." && "${i}" != ".." ]] ; then
	    if [[ -e ~/$i ]] ; then echo "(move)" && mv $FANCY_ARGS ~/$i ~/$i.orig ; fi
	    echo $SYMLINK_MSG && ln -s $FANCY_ARGS $REPODIR/$i ~/
	fi
    done
fi

if $debian; then
    echo -e $SEP"Basic binary packages"
    read -e -p "#### Install basic packages ($BASICS) ? [Y/n] " YN

    if [[ $YN == "y" || $YN == "Y" || $YN == "" ]] ; then
        sudo apt-get install $BASICS
    fi
fi

echo -e $SEP"Various menial janitor tasks"
read -e -p "#### Clean around? [Y/n] " YN
if [[ $YN == "y" || $YN == "Y" || $YN == "" ]] ; then
    if [[ ! -d ~/tmp ]] ; then mkdir -v ~/tmp ; else echo -e "~/tmp \t\t\tOK" ; fi
    if [[ ! -d /mnt/tmp ]] ; then sudo mkdir -v /mnt/tmp ; else echo -e "/mnt/tmp \t\tOK" ; fi
    if [[ ! $SHELL == "/bin/zsh" ]] ; then echo "Setting SHELL to zsh" && chsh -s /bin/zsh ; else echo -e "zsh shell \t\tOK" ; fi
    sudo adduser $(whoami) audio
fi


# Packages
if $debian; then
    echo -e $SEP"Binary package groups"
    read -e -p "#### Install package groups? [Y/n] " YN

    if [[ $YN == "y" || $YN == "Y" || $YN == "" ]] ; then
	for group in "${!pack[@]}" ; do
	    read -e -p "
## Install $group? (${pack[$group]})
[Y/n] " YN
	    if [[ $YN == "y" || $YN == "Y" || $YN == "" ]] ; then
		sudo apt-get install ${pack[$group]}
	    fi
	done
    fi
fi


echo -e $SEP"Various repositories"
read -e -p "#### Stuff? [Y/n] " YN
if [[ $YN == "y" || $YN == "Y" || $YN == "" ]] ; then
    for PROJECT in "${!VARIOUS[@]}" ; do
        VCSYSTEM=${VARIOUS[$PROJECT]:0:3}
        echo -e $SEP"$PROJECT ($SCRIPTDIR/$PROJECT/)"
        if [ ! -e $SCRIPTDIR/$PROJECT/ ] ; then
	    read -e -p "## Install $PROJECT in ($SCRIPTDIR/$PROJECT/)? [Y/n] " YN
	    if [[ $YN == "y" || $YN == "Y" || $YN == "" ]] ; then
	        cd $SCRIPTDIR && ${VARIOUS[$PROJECT]}
                # for i in *.py *.pl ; do `ln -vs "$i" ../` ; done
                cd $PROJECT && pwd
                for i in *.py *.pl ; do
                    [[ -e $i ]] && ln -sv $SCRIPTDIR/$PROJECT/$i $SCRIPTDIR/$i
                done
	    fi
        else
	    cd $SCRIPTDIR/$PROJECT/ && $VCSYSTEM pull
        fi
    done
fi

if [ ! -d "$LISPDIR" ] ; then mkdir -p $LISPDIR/ ; fi
echo -e $SEP"Various repositories"
read -e -p "#### (e)Lisp stuff? [Y/n] " YN
if [[ $YN == "y" || $YN == "Y" || $YN == "" ]] ; then
    for PROJECT in "${!LISP[@]}" ; do
        VCSYSTEM=${LISP[$PROJECT]:0:3}
        echo -e $SEP"$PROJECT ($LISPDIR/$PROJECT/)"
        if [ ! -e $LISPDIR/$PROJECT/ ] ; then
	          read -e -p "## Install $PROJECT in ($LISPDIR/$PROJECT/)? [Y/n] " YN
	          if [[ $YN == "y" || $YN == "Y" || $YN == "" ]] ; then
	              cd $LISPDIR && ${LISP[$PROJECT]}
	          fi
        else
	          cd $LISPDIR/$PROJECT/ && $VCSYSTEM pull
        fi
    done
fi

if (type -P firefox &>/dev/null); then
    PAGE=~/tmp/kituu-addons.html
    echo -e $SEP"Mozilla add-ons"
    for ADDON in "${!MOZ[@]}" ; do
	ADDONS=$ADDONS"    <li><a href='"${MOZ[$ADDON]}"'>$ADDON</a></li>\n"
	ADDON_NAMES=$ADDON", "$ADDON_NAMES
    done
    read -e -p "Install add-ons ($ADDON_NAMES)?
[Y/n] " YN
    if [[ $YN == "y" || $YN == "Y" || $YN == "" ]] ; then
	echo -e "
<html>
<head>
<style>
  body {font-family: sans-serif;background:#ccc;}
  hr {margin-top: 1em;width:35%;}
  img#logo {float:right;margin:1em;}
  img#id {width:25px;border:1px solid black;vertical-align:middle}
</style>
<title>Kituu: Install Mozilla addons for $(whoami)</title>
<link rel='shortcut icon' type='image/x-icon' href='http://mozilla.org/favicon.ico'></head>
<body style='background:#ccc'>
<a href='http://opensimo.org/play/?a=Azer0,Counternatures' title='Music!'>
<img id='logo' src='http://people.mozilla.com/~faaborg/files/shiretoko/firefoxIcon/firefox-128-noshadow.png' /></a>
  <h1>Hi $(whoami), click to install extension</h1>
  <ul>" > $PAGE
echo -e $ADDONS >> $PAGE
echo -e "</ul>
  <hr />
  <div style='margin-left: auto;margin-right: auto;width:75%;text-align:center;'><a href='https://github.com/xaccrocheur/kituu'><img id='id' src='http://a0.twimg.com/profile_images/998643823/xix_normal.jpg' /></a>&nbsp;&nbsp;Don't forget that you're a genius, $(whoami) ;)</div>
</body>
</html>" >> $PAGE && firefox $PAGE &
	# printf $ADDONS
    fi
fi

if [ -e $SCRIPTDIR/build-emacs.sh ]; then
    echo -e $SEP"Emacs trunk"
    read -e -p "## Download, build and install / update (trunk: ~500Mb initial DL) emacs? [Y/n] " YN
    if [[ $YN == "y" || $YN == "Y" || $YN == "" ]] ; then
        # sudo apt-get install build-dep emacs23
	build-emacs.sh
    fi
fi

read -e -p "
## Setup autostart apps? (Byobu / tmux and Gajim) [Y/n] " YN
if [[ $YN == "y" || $YN == "Y" || $YN == "" ]] ; then
[[ ! -d $AUTOSTART_DIR ]] && mkdir -v $AUTOSTART_DIR

    printf "[Desktop Entry]
Type=Application
Exec=gnome-terminal --command byobu --maximize --hide-menubar
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name[en_US]=Byobu
Name=Byobu
Comment[en_US]=Byobu tmuxed (zsh) shell (gnome-terminal)
Comment=Byobu tmuxed (zsh) shell" > $AUTOSTART_DIR/byobu.desktop

    printf "[Desktop Entry]
Name=Gajim
Comment=Gajim Internet Telephony
Exec=gajim
Icon=gajim
NoDisplay=false
Terminal=false
Type=Application
Encoding=UTF-8" > $AUTOSTART_DIR/gajim.desktop
fi

echo -e $SEP"...Done."

# NOTES
# packages in probation: apt-file zile gdm xfce4 xfce4-terminal xfce4-goodies xfce4-taskmanager libgtk2.0-dev
# pack[glamp]="apache2 mysql-server phpmyadmin"
# Thunderbird no longer opens xpis. (But it has a new add-ons panel that makes it much easier to search&install them).
# moz[GreaseMonkey_style_fix]="http://userscripts.org/scripts/source/36850.user.js"
# pack[xscreensaver]="xscreensaver-gl xscreensaver-gl-extra xscreensaver-data-extra xscreensaver-data"
# pack[xubuntu]="xubuntu"
# pack[dev_env]="perl-doc"
# pack[dev_libs]="libncurses5-dev libgnutls-dev librsvg2-dev libxpm-dev libjpeg62-dev libtiff-dev libgif-dev libqt4-dev libgtk-3-dev"
# pack[emacs_friends]="bbdb mailutils w3m-el"
# http://archive.canonical.com/ubuntu/pool/partner/a/adobe-flashplugin/adobe-flashplugin_11.2.202.236-0precise1_i386.deb
# https://addons.mozilla.org/en-US/firefox/addon/youtubedownloader/?src=userprofile
# sudo netstat -tlnp
