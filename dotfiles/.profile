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

        export HOMEBREW_GITHUB_API_TOKEN=1184c30c8dc3e6da0380702a56ad11dc8342c0b9
    fi
fi
# }}}

# Tool environments {{{

# For now, I think jenv is better for java than asdf. Mostly because jenv
# leaves me in control of installing whatever jdks/jres I want and then simply
# telling jenv about them.
which -s jenv && eval "$(jenv init -)"

# This must come _after_ brew PATH manipulations.
if which -s asdf; then

    # The 'asdf.sh' that we're sourceing below actually creates `asdf` as a
    # function. Therfore, we can't directly wrap it in a function called
    # `asdf`, so we'll do this little wrapper/alias trick, which we need to do
    # before the sourceing (not sure why).

    function asdf_() {
        if echo "$@" |grep '^install \+python' &>/dev/null; then
            echo "Use 'python-build <version> ~/.asdf/installs/python/...'"
        elif echo "$@" |grep '^install \+ruby' &>/dev/null; then
            echo "Use 'ruby-build <version> ~/.asdf/installs/ruby/...'"
        else
            command asdf "$@"
        fi
    }

    alias asdf='asdf_'

    # These 'brew --prefic ...' calls are way to slow.
    # source $(brew --prefix asdf)/asdf.sh
    # source $(brew --prefix asdf)/etc/bash_completion.d/asdf.bash
    source /usr/local/opt/asdf/asdf.sh
    source /usr/local/opt/asdf/etc/bash_completion.d/asdf.bash
fi

if which -s pyenv; then
    function pyenv() {
        echo "Use 'asdf' to manage python versions (via 'python-build')..."
    }
fi

if which -s rbenv; then
    function rbenv() {
        echo "Use 'asdf' to manage ruby versions (via 'ruby-build')..."
    }
fi
# }}}

# etc {{{

# Add ~/bin to path if user has one.
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi

if [ -d "/usr/local/sbin" ] ; then
    PATH="/usr/local/sbin:$PATH"
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
