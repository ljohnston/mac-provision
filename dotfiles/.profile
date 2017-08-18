# Modeline & Notes {{{
# vim: set sw=4 ts=4 sts=4 et tw=79 foldlevel=0 foldmethod=marker foldmarker={{{,}}}:
#
# ~/.profile: executed by the command interpreter for login shells.
# Note that this file is not read by bash(1), if ~/.bash_profile or
# ~/.bash_login exists.
#
# Specifically _not_ using a .bash_profile here so that we can have a single
# .profile for any and all shells we might be using. The intent will be to
# detect the shell we're in and load things accoringly.
#
# }}}

# {{{ bash
# include .bashrc if it exists
if [ -n "$BASH_VERSION" ]; then
    if [ -f "$HOME/.bashrc" ]; then
        . "$HOME/.bashrc"
    fi
fi
# }}}

# OS X {{{
if [[ $OSTYPE == *darwin* ]]; then

    # If we're running brew, let's make sure that /usr/local/bin is first in
    # our PATH to ensure our brew installed packages will take precedence.
    if which brew >> /dev/null; then
        # Is there a better way to do this?
        path=$(echo $PATH \
            |sed -E 's|^/usr/local/bin:||' \
            |sed -E 's|:/usr/local/bin$||' \
            |sed -E 's|:?/usr/local/bin:|:|' \
            |sed -E 's|:/usr/local/bin:?|:|')
        PATH="/usr/local/bin:${path}"
    fi
fi
# }}}
 
# etc {{{

# Add ~/bin to path if user has one.
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi

export EDITOR=vim

# }}}

# Local Modifications {{{
#
# If we need local profile mods, we'll make them in ~/.profile.local. This will
# allow us to keep our "core" dotfiles the same across all locations, yet still
# give us the opportunity to customize things for specific boxes, sites, etc.
#

if [ -f "$HOME/.profile.local" ]; then
    . "$HOME/.profile.local"
fi
# }}}
