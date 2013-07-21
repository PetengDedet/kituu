#!/bin/bash

srcdir=~/src

declare -A pack
pack[triceratops]="git clone git://git.code.sf.net/p/triceratops/code"
pack[amsynth]="git clone https://code.google.com/p/amsynth"
pack[sord]="svn co http://svn.drobilla.net/sord/trunk"
pack[lilv]="svn co http://svn.drobilla.net/lad/trunk/lilv"
pack[drumkv1]="svn co http://svn.code.sf.net/p/drumkv1/code/trunk"
pack[ardour]="git clone git://git.ardour.org/ardour/ardour.git"

# svn co http://svn.drobilla.net/lad/trunk drobilla-lad
# svn checkout svn://svn.code.sf.net/p/arpage/code/trunk arpage

init=true

[[ -d $srcdir ]] && cd $srcdir || mkdir -v $srcdir && cd $srcdir

read -e -p "## Install deps? [Y/n] " yn
if [[ $yn == "y" || $yn == "Y" || $yn == "" ]] ; then
    sudo apt-get install autoconf libboost-dev libglibmm-2.4-dev libsndfile-dev liblo-dev libxml2-dev uuid-dev libcppunit-dev libfftw3-dev libaubio-dev liblrdf-dev libsamplerate-dev libserd-dev libsratom-dev libsuil-dev libgnomecanvas2-dev libgnomecanvasmm-2.6-dev libcwiid-dev libgtkmm-2.4-dev wine-dev
fi

function build_waf {

    if [[ $1 = "ardour" ]] ; then
	read -e -p "## Build ardour with Windows VST support? [Y/n] " yn
	if [[ $yn == "y" || $yn == "Y" || $yn == "" ]] ; then
            build_flags="--windows-vst"
        else
            build_flags=""
        fi
    fi

    ./waf configure $build_flags && ./waf && sudo ./waf install
}

function build_make {
    if [[ $init ]] ; then
        if [[ -f autogen.sh ]] ; then
            ./autogen.sh
        else
            make -f Makefile.svn
        fi
    fi
    ./configure && make && sudo make install
}

function update_package {

    echo -e "\n## $1"
    pwd
    if $init ; then
        [[ -f ./waf ]] && build_waf $1 || build_make
    else
        if [[ $vcsystem == "git" ]] ; then
            git pull 1>&1 | grep "Already up-to-date."
        else
            svn up 1>&1 | grep "At revision"
        fi

        if [ ! $? -eq 0 ]; then
            read -e -p "## Branch moved, build and install $1? [Y/n] " yn
            if [[ $yn == "y" || $yn == "Y" || $yn == "" || $init ]] ; then
                [[ -f ./waf ]] && build_waf || build_make
            fi
        fi
    fi
}

for package in "${!pack[@]}" ; do
    vcsystem=${pack[$package]:0:3}
    [[ $vcsystem = "svn" ]] && vcupdatecommand="update" || vcupdatecommand="pull"
    [[ $vcsystem = "svn" ]] && vcinitcommand="checkout" || vcinitcommand="clone"
    # echo "URL of $package ($vcsystem $vcupdatecommand) is ${pack[$package]}"

    # echo -e $sep"$package ($srcdir/$package/)"
    if [[ ! -d $srcdir/$package ]] ; then
        init=true
        echo
	read -e -p "## $vcinitcommand $package in ($srcdir/$package/)? [Y/n] " yn
	if [[ $yn == "y" || $yn == "Y" || $yn == "" ]] ; then
	    # cd $srcdir && ${pack[$package]}
            cd $srcdir && ${pack[$package]} $package && cd $package
            update_package $package
	fi
    else
        init=false
	cd $srcdir/$package
        update_package $package
    fi
done
