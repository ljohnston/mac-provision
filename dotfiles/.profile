# Modeline & Notes {{{
# vim: set sw=4 ts=4 sts=4 et tw=79 foldlevel=0 foldmethod=marker foldmarker={{{,}}}:
#
# ~/.profile: executed by the command interpreter for login shells.
# Note that this file is not read by bash(1), if ~/.bash_profile or
# ~/.bash_login exists.
#
# }}}

# {{{ bash
# On OS X, every new terminal window or tab is an interactive login shell. On
# Linux, however, these are typically interactive non-login shells. So on Linux
# _only_ .bashrc is read. To make OS X behave more like Linux (and allow these
# dotfiles to be more cross-platform), we'll source ~/.bashrc here.
if [ -r "$HOME/.bashrc" ]; then
    . "$HOME/.bashrc"
fi
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
