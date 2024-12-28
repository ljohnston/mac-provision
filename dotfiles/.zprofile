# Modeline & Notes {{{
# vim: set sw=4 ts=4 sts=4 et tw=79 foldlevel=0 foldmethod=marker foldmarker={{{,}}}:
#
# }}}

#
# Typically set PATH here. A decent link on zsh init:
#
#   https://mac.install.guide/terminal/zshrc-zprofile
#

# Homebrew {{{

# On Apple Silicon Macs brew installs to /opt/homebrew.
if [ -x /opt/homebrew/bin/brew ]; then
    eval $(/opt/homebrew/bin/brew shellenv)
fi

# On Intel Macs, brew installs in the standard '/usr/local/bin' dirctory...
if [ -x /usr/local/bin/brew ]; then

    # ... so brew will already be on the path, but here we'll make sure
    # that '/usr/local/bin' precedes all of the other "standard" system
    # directories to ensure our brew installed packages take precedence.
    
    path=$(echo $PATH \
        |sed -E 's|^/usr/local/bin:||' \
        |sed -E 's|:/usr/local/bin$||' \
        |sed -E 's|:?/usr/local/bin:|:|' \
        |sed -E 's|:/usr/local/bin:?|:|')
    PATH="/usr/local/bin:${path}"
fi

# }}}

# PATH {{{

if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi

if [ -d "/usr/local/sbin" ] ; then
    PATH="/usr/local/sbin:$PATH"
fi


export CLICOLOR=1
export EDITOR=vim

# }}}


# Local Config {{{
# [[ -f ~/.zprofile.local ]] && source ~/.zprofile.local
# }}}
