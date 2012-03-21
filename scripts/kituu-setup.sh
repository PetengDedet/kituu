#!/bin/bash

shopt -s dotglob
kituudir=~/.kituu
lispdir=~/.emacs.d/lisp
scriptsdir=~/scripts
sep="\n################# "

echo -e $sep"Kituu! #################"

if [ ! -d $kituudir ]
then
echo -e $sep"No existing $kituudir, so"
    cd && git clone git@github.com:xaccrocheur/kituu.git
else
echo -e $sep"Found $kituudir, so"
    cd $kituudir && git pull
fi

for i in * ; do
    if [[ "${i}" != ".git" && "${i}" != "README.org" && "${i}" != "." && "${i}" != ".." && ! -L ~/$i && "${i}" != "*.elc" ]] ; then
	if [[ -e ~/$i ]] ; then
	    mv -v ~/$i ~/$i.orig
	    ln -sv $kituudir/$i ~/
	else
	    ln -sv $kituudir/$i ~/
	fi
    else
	[[ "${i}" != ".git" ]] && [[ "${i}" != "README.org" ]] && echo -e " \033[1m$i\033[0m \t > \t is already a symlink"
    fi
done

echo -e $sep"Various binary packages"
if [ -e $scriptsdir/offlineimap/ ] ; then
    sudo urpmi perl-doc bzr
fi

if [ ! -e $scriptsdir/git-completion.bash ]
  then
echo -e $sep"Git completion ($scriptsdir/git-completion.bash)"
    curl -L https://github.com/git/git/raw/master/contrib/completion/git-completion.bash > $scriptsdir/git-completion.bash
fi

echo -e $sep"Tabbar ($lispdir/tabbar/)"
if [ ! -e $lispdir/tabbar/ ] ; then
    cd $lispdir && git clone https://github.com/dholm/tabbar.git
else
    cd $lispdir/tabbar/ && git pull
fi

echo -e $sep"nXhtml ($lispdir/nxhtml/)"
if [ ! -e $lispdir/nxhtml/ ] ; then
    cd $lispdir && bzr branch lp:nxhtml
else
    cd $lispdir/tabbar/ && bzr pull
fi

# echo -e $sep"Smart-tab ($lispdir/smart-tab/)"
# if [ ! -e $lispdir/smart-tab/ ] ; then
#     cd $lispdir && git clone https://github.com/genehack/smart-tab.git
# else
#     cd $lispdir/smart-tab/ && git pull
# fi

echo -e $sep"Offlineimap ($scriptsdir/offlineimap/)"
if [ ! -e $scriptsdir/offlineimap/ ] ; then
    cd $scriptsdir && git clone https://github.com/spaetz/offlineimap.git
    ln -sv offlineimap/offlineimap.py .
else
    cd $scriptsdir/offlineimap/ && git pull
fi

echo -e $sep"...Done."
