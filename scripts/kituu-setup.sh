#!/bin/bash

shopt -s dotglob
kituudir=~/.kituu
lispdir=~/.emacs.d/lisp
scriptsdir=~/scripts
sep="\n################# "

echo -e "Kituu!"
# clone &| check
if [ ! -d $kituudir ]
then
    echo -e $sep"No existing $kituudir, cloning..."
    git clone git@github.com:xaccrocheur/kituu.git
else
    echo -e $sep"Found $kituudir, fetching..."
    cd $kituudir
    git fetch && git reset --hard origin/master
fi

# Install
for i in * ; do
    if [[ "${i}" != ".git" &&  "${i}" != "README.org" && "${i}" != "." && "${i}" != ".." && ! -L ~/$i ]] ; then
	if [[ -e ~/$i ]] ; then
	    mv ~/$i ~/$i.orig
	    echo -e "\033[1m~/$i\033[0m has been backuped to ~/$i.orig"
	    ln -s $kituudir/$i ~/
	    echo -e "~/$i is now a link to $kituudir/$i"
	else
	    ln -s $kituudir/$i ~/
	    echo -e "\033[1m~/$i\033[0m \t -> \t $kituudir/\033[1m$i\033[0m"
	fi
    else
	[[ "${i}" != ".git" ]] && [[ "${i}" != "README.org" ]] && echo -e " \033[1m$i\033[0m \t > \t is already a symlink"
    fi
done

if [ ! -e $scriptsdir/git-completion.bash ]
  then
    echo -e $sep"Installing Git completion..."
    curl -L https://github.com/git/git/raw/master/contrib/completion/git-completion.bash > ~/scripts/git-completion.bash
fi

if [ ! -e $lispdir/tabbar/ ]
  then
    echo -e $sep"Installing Tabbar in $lispdir/tabbar/"
    git clone https://github.com/dholm/tabbar.git && echo -e $sep"...Done."
    rm -rf tabbar/.git/
fi

if [ ! -e $scriptsdir/offlineimap/ ]
  then
    echo -e $sep"Installing offlineimap in $scriptsdir/offlineimap/"
    git clone https://github.com/spaetz/offlineimap.git && echo -e $sep"...Done."
    ln -s offlineimap/offlineimap.el $scriptsdir
fi

if [ ! -e $lispdir/offlineimap.el ]
  then
    echo -e $sep"Installing offlineimap.el in $lispdir/"
    git clone http://git.naquadah.org/git/offlineimap-el.git && echo -e $sep"...Done."
    cp offlineimap-el/offlineimap.el . && rm -rf offlineimap-el/
fi


