# Modeline & Notes {{{
# vim: set sw=4 ts=4 sts=4 et tw=79 foldlevel=0 foldmethod=marker foldmarker={{{,}}}:
#
# .bashrc
# }}}

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# General {{{

export CLICOLOR=1
set -o vi

# }}}

# Aliases {{{

alias gw='./gradlew'

alias ll='ls -l'
alias la='ls -la'

alias c='clear'

# Note that there are functions below for grepping history.
alias h='history'
alias hl='history |less'

if which vagrant >> /dev/null; then
    alias vup='vagrant up'
    alias vd='vagrant destroy'
    alias vdf='vagrant destroy --force'
    alias vp='vagrant provision'
    alias vssh='vagrant ssh'
    alias vst='vagrant status'
    alias vsnap='vagrant snapshot'
fi
# }}}

# Prompt {{{
#
# We'll use bash-git-prompt (https://github.com/magicmonty/bash-git-prompt) if
# it's installed.
#
# Note that we rely on an installation done as a simple 'git clone ...' as
# opposed to a brew install or some other method. This can be done as:
#
# $ cd
# $ git clone https://github.com/magicmonty/bash-git-prompt.git .bash-git-prompt
# $ cd .bash-git-prompt
# $ git tag
# $ git checkout <tag>
#
# If bash-git-prompt is NOT isntalled, we'll put together our own prompt that
# includes the following:
#
# - timestamp 
# - PWD
#   - home directory (HOME) is replaced with a ~
#   - last pwdmaxlen characters of the PWD are displayed
#   - leading partial directory names replaced with ".." if path too long
# - username@host 
# 
# Note that the prompt is split across two lines. That's not really my
# preference, but long prompts seem to hose up command recall when using
# 'set -o vi'.
#
# Do this BEFORE the history stuff as that attaches itself to the prompt as
# well.
#

if [ -n "${VIM}" ]; then
    :
elif [ -f ~/.bash-git-prompt/gitprompt.sh ]; then
    GIT_PROMPT_THEME=Solarized
    source ~/.bash-git-prompt/gitprompt.sh
else
    bash_prompt_command() {
    
        # How many characters of the $PWD should be kept?
        local pwdmaxlen=20
    
        # Handle pwd display truncation if path is too long.
        local trunc_symbol=".."
        local dir=${PWD##*/}
        pwdmaxlen=$(( ( pwdmaxlen < ${#dir} ) ? ${#dir} : pwdmaxlen ))
        NEW_PWD=${PWD/$HOME/"~"}
        local pwdoffset=$(( ${#NEW_PWD} - pwdmaxlen ))
        if [ ${pwdoffset} -gt "0" ] ; then
            NEW_PWD=${NEW_PWD:$pwdoffset:$pwdmaxlen}
            NEW_PWD=${trunc_symbol}/${NEW_PWD#*/}
        fi
    
        #
        # Write the hostname in the terminal's tab title. Putting this
        # here will allow us to get an update not just on login to a new
        # box, but on exiting back to a previous box as well.
        #
    
        case $TERM in
            xterm*)
                echo -en "\033];$(hostname -s)\007"
                ;;
        esac
    }
    
    bash_prompt() {
        local HOST=$(hostname)
        local NONE="\[$(tput sgr0)\]"
    
        local K="\[$(tput setaf 0)\]"
        local R="\[$(tput setaf 1)\]"
        local G="\[$(tput setaf 2)\]"
        local Y="\[$(tput setaf 3)\]"
        local B="\[$(tput setaf 4)\]"
        local M="\[$(tput setaf 5)\]"
        local C="\[$(tput setaf 6)\]"
        local W="\[$(tput setaf 7)\]"
    
        local EMK="\[$(tput bold; tput setaf 0)\]"
        local EMR="\[$(tput bold; tput setaf 1)\]"
        local EMG="\[$(tput bold; tput setaf 2)\]"
        local EMY="\[$(tput bold; tput setaf 3)\]"
        local EMB="\[$(tput bold; tput setaf 4)\]"
        local EMM="\[$(tput bold; tput setaf 5)\]"
        local EMC="\[$(tput bold; tput setaf 6)\]"
        local EMW="\[$(tput bold; tput setaf 7)\]"
    
        local BGK="\[$(tput setab 0)\]"
        local BGR="\[$(tput setab 1)\]"
        local BGG="\[$(tput setab 2)\]"
        local BGY="\[$(tput setab 3)\]"
        local BGB="\[$(tput setab 4)\]"
        local BGM="\[$(tput setab 5)\]"
        local BGC="\[$(tput setab 6)\]"
        local BGW="\[$(tput setab 7)\]"
    
        local UC=$C                 # user's color
        [ $UID -eq "0" ] && UC=$R   # root's color
    
        # History Search doesn't work in deep subdirs.
        #PS1="${Y}[${W}\t${Y}] [${UC}\u@\h${W}:${EMB}\${NEW_PWD}${NONE}${Y}] ${W}\$ ${NONE}"
    
        # Works, but everything is bold beyond pwd.
        #PS1="${Y}[${W}\t${Y}] [${UC}\u@\h${W}:${EMB}\${NEW_PWD}${Y}] ${W}\$ ${NONE}"
    
        # Works, but nothing (pwd nor anything else) is bold.
        #PS1="${Y}[${W}\t${Y}] [${UC}\u@\h${W}:${B}\${NEW_PWD}${Y}] ${W}\$ ${NONE}"
    
        PS1="\n${Y}[${W}\t${Y}] [${B}\${NEW_PWD}${Y}]\n[${UC}\u@\h${Y}] ${W}\$ ${NONE}"
    }
    
    if tty -s; then
      PROMPT_COMMAND="bash_prompt_command;$PROMPT_COMMAND"
      bash_prompt
      unset bash_prompt
    fi
fi

# }}}

# History {{{
# Intent here is: 
# - Unlimited (or effectively unlimited) history.
# - History from current shell _not_ available to concurrently running shells.
# - History from the current shell available to new shells started while the
# current shell is still active.
#
# Got most of this from:
#
# http://unix.stackexchange.com/questions/1288/preserve-bash-history-in-multiple-terminal-windows
#
# Note that as the above post mentions, there can be issues with referencing
# commands by number in this scheme.
#

shopt -s histappend

HISTSIZE=10000
HISTFILESIZE=100000
HISTCONTROL=ignorespace:ignoredups

history() {
  _bash_history_sync
  builtin history "$@"
}

_bash_history_sync() {
  builtin history -a            # Append session history to history file.
  HISTFILESIZE=$HISTFILESIZE    # Resetting HISTFILESIZE will force history
                                # file to be truncated to the specified size.
                                # Without this, file will only be truncated
                                # when the shell is closed.
}

PROMPT_COMMAND="_bash_history_sync;$PROMPT_COMMAND"

# }}}

# History Grep {{{

## History grep that builds up final command to grep for multiple                
## items in the command history.                                                 
## Usage: hg <string> <string> <string> ...                                      

hg()                                                                             
{                                                                                
    GREP=grep                                                                    
    MYPIPE="|"                                                                   
    CMD=                                                                         
    for i in "$@"                                                                
    do                                                                           
      if [[ -z $CMD ]]; then                                                     
        CMD="history $MYPIPE $GREP $i |grep -v '^[0-9]\+ \+hf\?g '"                                           
      else                                                                       
        CMD="$CMD $MYPIPE $GREP $i"                                              
      fi                                                                         
    done                                                                         
    eval $CMD                                                                    
}	

hfg()                                                                             
{                                                                                
    GREP=grep                                                                    
    MYPIPE="|"                                                                   
    CMD=                                                                         
    for i in "$@"                                                                
    do                                                                           
      if [[ -z $CMD ]]; then                                                     
        CMD="cat $HISTFILE $MYPIPE $GREP $i |grep -v '^hf\?g '"                                           
      else                                                                       
        CMD="$CMD $MYPIPE $GREP $i"                                              
      fi                                                                         
    done                                                                         
    eval $CMD                                                                    
}	

# }}}

# SSH Config Autocompletion {{{

export COMP_WORDBREAKS=${COMP_WORDBREAKS/\:/}                                             
                                                                                          
_sshcomplete() {                                                                          
    # parse all defined hosts from .ssh/config                                            
    if [ -r $HOME/.ssh/config ]; then                                                     
        COMPREPLY=($(compgen -W "$(grep ^Host $HOME/.ssh/config | awk '{print $2}' )" -- ${COMP_WORDS[COMP_CWORD]}))
    fi                                                                                    

    return 0                                                                              
}                                                                                         

complete -o default -o nospace -F _sshcomplete ssh  
# }}}

# Local Modifications {{{
#
# If we need local .bashrc mods, we'll make them in ~/.bashrc.local. This will
# allow us to keep our "core" dotfiles the same across all locations, yet still
# give us the opportunity to customize things for specific boxes, sites, etc.
#

if [ -f "$HOME/.bashrc.local" ]; then
    . "$HOME/.bashrc.local"
fi
# }}}

