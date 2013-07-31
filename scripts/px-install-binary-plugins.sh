#!/bin/bash

UNPACK_DIR=~/src/PLUGIN_ARCHIVES
LV2_DIR=/usr/local/lib/lv2
LXVST_DIR=/usr/local/lib/lxvst
SRC_DIR=~/src

PLUGIN_ARCHIVES="http://downloads.sourceforge.net/project/distrho/Ports/HighLife/highlife_linux32_20120518.7z
http://www.extentofthejam.com/DigitsVST-Linux-1.3.tar.gz
https://sites.google.com/site/ccernnaudio/vst-plugins/backup.zip
http://downloads.sourceforge.net/project/distrho/Ports/Arctican-Plugins/arctican-plugins_linux32_20120518.7z
http://www.mucoder.net/en/hypercyclic/v0101/download/latest/hypercyclic.1.1.367.linux.zip
http://downloads.sourceforge.net/project/distrho/Ports/dRowAudio-Plugins/drowaudio-plugins_linux32_20120518.7z
http://downloads.sourceforge.net/project/distrho/Ports/Juced-plugins/juced-plugins_linux32_20120518-2.7z
http://downloads.sourceforge.net/project/distrho/Ports/TAL-Plugins/tal-plugins_linux32_20120518.7z
http://downloads.sourceforge.net/project/distrho/Ports/HybridReverb2/hybridreverb2_linux32_20120518.7z
http://downloads.sourceforge.net/project/distrho/Ports/Wolpertinger/wolpertinger_linux32_20120518-2.7z"

BIN_REPOS="deb http://ppa.launchpad.net/gnu-psychosynth-team/ppa/ubuntu $(lsb_release -c -s) main"

declare -A PACKS
# PACKS[00-lv2]="svn checkout http://lv2plug.in/repo/trunk"
# PACKS[01-drobilla-lad]="svn co http://svn.drobilla.net/lad/trunk"
# PACKS[03-ntk]="git clone git://git.tuxfamily.org/gitroot/non/fltk.git"
# PACKS[01-add64]="git clone git://git.code.sf.net/p/add64/code"
PACKS[02-triceratops]="git clone git://git.code.sf.net/p/triceratops/code"
# PACKS[02-amsynth]="git clone https://code.google.com/p/amsynth"
PACKS[02-drumkv1]="svn co http://svn.code.sf.net/p/drumkv1/code/trunk"
PACKS[02-samplv1]="svn co http://svn.code.sf.net/p/samplv1/code/trunk"
PACKS[02-synthv1]="svn co http://svn.code.sf.net/p/synthv1/code/trunk"
PACKS[03-sorcer]="git clone https://github.com/harryhaaren/openAV-Sorcer.git"
PACKS[03-qtractor]="svn co http://svn.code.sf.net/p/qtractor/code/trunk"
# PACKS[04-ardour]="git clone git://git.ardour.org/ardour/ardour.git"
PACKS[01-phasex]="git clone https://github.com/williamweston/phasex.git"

BIN_BUILD="autoconf libqt4-dev dssi-dev librubberband-dev libboost-dev libglibmm-2.4-dev libsndfile-dev liblo-dev libxml2-dev uuid-dev libcppunit-dev libfftw3-dev libaubio-dev liblrdf-dev libsamplerate-dev libgnomecanvas2-dev libgnomecanvasmm-2.6-dev libcwiid-dev libgtkmm-2.4-dev libalsa-ocaml-dev libjack-dev lv2-dev liblilv-dev libsuil-dev libsratom-dev liblash-compat-dev lv2-c++-tools libpaq-dev"

BIN_PLUGINS="invada-studio-plugins-lv2 so-synth-lv2 swh-lv2 mda-lv2 wsynth-dssi xsynth-dssi zynaddsubfx-dssi calf-plugins abgate aeolus amb-plugins autotalent caps cmt eq10q foo-yc20 hexter ir.lv2 lv2fil lv2vocoder mcp-plugins mda-lv2 swh-lv2 tap-plugins vocproc wah-plugins xsynth-dssi zita-at1 fluid-soundfont-gm amsynth whysynth"

BIN_PROD="linux-lowlatency qmidinet qjackctl vmpk harmonyseq"


echo "### $(basename $0) : ${#PACKS[@]} top-level repositories and ${#PLUGIN_ARCHIVES[@]} binary plugin archives
## Use -f to ignore VC state & force build"


DEBIAN=$(type -P apt-get)
[[ $1 == "-f" ]] && FORCE_BUILD=true || FORCE_BUILD=false
[[ $1 == "-y" ]] && ALWAYS_YES=true || ALWAYS_YES=false

readarray -t PACKS_SORTED < <(printf '%s\n' "${!PACKS[@]}" | sort)

function build_waf {
    if [[ $PACKAGE = "ardour" ]] ; then
	read -e -p "## Build ardour with Windows VST support? [Y/n] " YN
	if [[ $YN == "y" || $YN == "Y" || $YN == "" ]] ; then
            sudo apt-get install wine-dev
            BUILD_FLAGS="--windows-vst --program-name=ardour3-vst"
        else
            BUILD_FLAGS=""
        fi
    fi
    ./waf clean
    ./waf configure $BUILD_FLAGS && ./waf && sudo ./waf install
}

function build_make {
    if [[ $INIT ]] ; then
        if [[ -f Makefile.svn ]] ; then
            [[ -f autogen.sh ]] && ./autogen.sh ||  make -f Makefile.svn
        elif [[ -f Makefile.am ]] ; then
            aclocal && autoconf && automake && autoheader
        fi
    fi

    if [[ $PACKAGE = "phasex" ]] ; then
        BUILD_FLAGS="--enable-arch=native --enable-parts=2"
    else
        BUILD_FLAGS=""
    fi

    make clean
    ./configure && make && sudo make install
}

function vc_check {
    [[ $VC_SYSTEM == "git" ]] && VC_LOG_COMMAND="git log -1" || VC_LOG_COMMAND="svn log -l 1"

    VC_PRE=$(${VC_LOG_COMMAND})
    $VC_SYSTEM $VC_UPDATE_CMD
    VC_POST=$(${VC_LOG_COMMAND})

    [[ "$VC_PRE" != "$VC_POST" ]] && return 0 || return 1
}

function update_package {
    if [[ $INIT = true || $FORCE_BUILD = true ]] ; then
        [[ -f ./waf ]] && build_waf || build_make
    else
        vc_check
        if [ $? -eq 0 ]; then
            read -e -p "## Branch moved, build and install $PACKAGE? [Y/n] " YN
            if [[ $YN == "y" || $YN == "Y" || $YN == "" || $ALWAYS_YES ]] ; then
                [[ -f ./waf ]] && build_waf || build_make
            fi
        fi
    fi
}

sudo usermod -a -G audio $USER && echo "## User $USER in group audio"

for REPO in $BIN_REPOS ; do
    echo "## Setup $REPO repository"
    sudo apt-add-repository '${REPO}' && echo "## Setup $REPO repository"
done

sudo apt-get update

[[ $DEBIAN ]] && read -p "
## Install / Update build deps? ($BIN_BUILD) [Y/n] " YN || YN="no"
[[ $YN == "y" || $YN == "Y" || $YN == "" ]] && sudo apt-get install $BIN_BUILD
[[ $DEBIAN ]] && read -e -p "
## Install / Update prod apps? ($BIN_PROD) [Y/n] " YN || YN="no"
[[ $YN == "y" || $YN == "Y" || $YN == "" ]] && sudo apt-get install $BIN_PROD
[[ $DEBIAN ]] && read -e -p "
## Install / Update plugins? ($BIN_PLUGINS) [Y/n] " YN || YN="no"
[[ $YN == "y" || $YN == "Y" || $YN == "" ]] && sudo apt-get install $BIN_PLUGINS

read -e -p "## Install / update source repos? [Y/n] " YN
if [[ $YN == "y" || $YN == "Y" || $YN == "" ]] ; then
    [[ -d $SRC_DIR ]] && cd $SRC_DIR || mkdir -v $SRC_DIR && cd $SRC_DIR

    for PACKAGE in "${PACKS_SORTED[@]}" ; do
        VC_SYSTEM=${PACKS[$PACKAGE]:0:3}
        [[ $VC_SYSTEM = "svn" ]] && VC_UPDATE_CMD="update" || VC_UPDATE_CMD="pull"
        PACKAGE_CLONE_COMMAND="${PACKS[$PACKAGE]}"
        PACKAGE=${PACKAGE:3:$(( ${#PACKAGE} -3 ))}

        echo -e "\n## $PACKAGE"

        if [[ ! -d $SRC_DIR/$PACKAGE ]] ; then
            INIT=true
            # echo
            read -e -p "## Clone / Checkout $PACKAGE in ($SRC_DIR/$PACKAGE/)? [Y/n] " YN
            if [[ $YN == "y" || $YN == "Y" || $YN == "" ]] ; then
                cd $SRC_DIR && $PACKAGE_CLONE_COMMAND $PACKAGE && cd $PACKAGE && update_package
            fi
        else
            INIT=false
            cd $SRC_DIR/$PACKAGE && update_package
        fi
    done
fi

read -e -p "## Install bin archives? [Y/n] " YN
if [[ $YN == "y" || $YN == "Y" || $YN == "" ]] ; then

    cd $UNPACK_DIR

    for D_URL in $PLUGIN_ARCHIVES ; do

        rm -rf $UNPACK_DIR/*

        D_FILE=$(basename $D_URL)
        D_URI=${D_URL:0:$( expr ${#D_URL} - ${#D_FILE} )}
        D_FILE_TGZ=$(echo "$D_FILE" | grep "tar.gz" )
        [[ $D_FILE_TGZ ]] && EXT_COMMAND="tar -xzf " || EXT_COMMAND="7z x "

        echo -e "
## Downloading ${D_FILE} (from $D_URI)"

        wget -q --secure-protocol=auto $D_URL && echo "### Downloaded $D_FILE in $UNPACK_DIR" && $EXT_COMMAND $D_FILE > /dev/null
        PLUGIN_LV2=$(find . -name "*.lv2")
        PLUGIN_VST=$(find . -name "*.so")

        if [[ $PLUGIN_LV2 ]] ; then
            PLUGIN_VST=""
            D_DEST_DIR=$LV2_DIR
        else
            if [[ $PLUGIN_VST && ! $PLUGIN_LV2 ]] ; then
                D_DEST_DIR=$LXVST_DIR
            fi
        fi

        ALL_PLUGINS="$PLUGIN_VST $PLUGIN_LV2"

        for D_PLUGIN in $ALL_PLUGINS ; do
            sudo cp -R $D_PLUGIN $D_DEST_DIR &&  echo "### Done copying $D_PLUGIN to $D_DEST_DIR"

        done
    done
fi

if [ $(pgrep pulseaudio) ] ; then
    read -e -p "## Remove PulseAudio? [Y/n] " YN
    if [[ $YN == "y" || $YN == "Y" || $YN == "" ]] ; then
        sudo apt-get autoremove pulseaudio
        sudo apt-get install volumeicon

        printf "[Desktop Entry]
Type=Application
Exec=volumeicon
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=Tray icon for ALSA
Comment=Added on $(date +%y-%m-%d-%Hh%M)" > ~/.config/autostart/volumeicon.desktop

        printf "[StatusIcon]
stepsize=5
lmb_slider=true
mmb_mute=true
use_horizontal_slider=false
show_sound_level=false
onclick=gnome-terminal --title='ALSA Mixer' --command 'alsamixer'
theme=White Gnome

[Hotkeys]
up_enabled=false
down_enabled=false
mute_enabled=false
up=XF86AudioRaiseVolume
down=XF86AudioLowerVolume
mute=XF86AudioMute

[Alsa]
card=default" > ~/.config/volumeicon/volumeicon
    fi
fi


# gsettings set com.canonical.Unity.Panel systray-whitelist "['all']"
# http://www.webupd8.org/2013/05/how-to-get-systray-whitelist-back-in.html
echo "## All done."
