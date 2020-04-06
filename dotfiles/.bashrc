# Modeline & Notes {{{
# vim: set sw=4 ts=4 sts=4 et tw=79 foldlevel=0 foldmethod=marker foldmarker={{{,}}}:
#
# .bashrc
# }}}

# Startup Script Profiling {{{
#
# Occassionally I end up with so much crap in my bash startup scripts that
# things become really slow. When that happens, tracking down the culprit can
# be difficult. Uncommenting the following and examining the specified log file
# can identify commands that take a while to execute. 
# 
# When needed, uncomment the following, start a new shell (it will appear to
# hang because the IO in it has been messed with), exit it, and examine the log
# file.
#
# Some tips when digging into the log file:
#
# The way PS4 works is each spawned process adds a '+' sign to the front of the
# prompt. The log file can be quite long, so it can be more informative to
# ignore the lower-level processes. Specifically:
#
#   $ grep -E '^\+{1,2} ' <logfile>
#
#   The above should give all of the commands directly called from the startup
#   scripts. Increasing the second digit in the brackets will increase the
#   detail. 
#
# With the following in effect, startup will be _really_ slow. The relative
# timings in the log file, however, should be informative.
#

# PS4='+ $(gdate "+%s.%N")\011 '
# LOGFILE=/tmp/bashstart.$$.log
#
# echo
# echo 'Startup script profiling is enabled.'
# echo "Your new shell will appear to hang, but that's actually not the case."
# echo "Exit the shell by typing 'exit'<CR>."
# echo "You will find profiling details in '${LOGFILE}'"
# exec 3>&2 2>${LOGFILE}
# set -x

# }}}

# General {{{

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

export CLICOLOR=1
set -o vi

# }}}

# Completion {{{

# Requires 'brew install bash-completion@2'
# See: https://github.com/scop/bash-completion
export BASH_COMPLETION_COMPAT_DIR="/usr/local/etc/bash_completion.d"
[[ -r "/usr/local/etc/profile.d/bash_completion.sh" ]] && . "/usr/local/etc/profile.d/bash_completion.sh"

# }}}

# Aliases {{{

alias gw='./gradlew'

alias ll='ls -l'
alias la='ls -la'

alias less='less -R'

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

# Kubernetes Tooling {{{
if which kubectl >> /dev/null; then

    alias k='kubectl'
    source <(kubectl completion bash)
    complete -o default -F __start_kubectl k

    # NOTE: `$ complete |grep <comman>` to get 
    # current completion for <command>.

    if which kubectx >> /dev/null; then
        alias kx='kubectx'
        complete -F _kube_contexts kx
    fi

    if which kubens  >> /dev/null; then
        alias kn='kubens' 
        complete -F _kube_namespaces kn
    fi

    #
    # FUNCTION
    #   kc
    #
    # DESC
    #   Manage the KUBECONFIG environment variable.
    #
    # USAGE
    #   kc [<context>|all|-]
    #   
    #   where:
    #     <context> dynamically generates a <context>-specific
    #               kubeconfig file and sets KUBECONFIG accordingly
    #     all       sets KUBECONFIG to all available kubeconfigs (see 
    #               below KUBECONFIG SOURCES for details)
    #     -         Unsets KUBECONFIG
    #
    #   Running 'kc' with no arguments shows the current KUBECONFIG
    #   environment variable setting.
    #
    #   Running 'kc <context>' allows the user to effectively make a
    #   single context available within their current shell, thereby
    #   protecting that shell from context or namespace changes made
    #   in other shells.
    #
    # KUBECONFIG SOURCES
    #   Available kubeconfigs come from the following sources:
    #
    #     ~/.kube/config
    #       The default location for kubectl to look for its kubeconfigs.
    #     ~/.kube/*.kubeconfig
    #       Any files with a ".kubeconfig" extension in the ~/.kube
    #       will be added as available kubeconfigs.
    #
    #   The user can manage their sources however they like. In general,
    #   however, the suggested strategy is to maintain more static, or 
    #   long-lived, cluster configs in the starnadard ~/kube/config file,
    #   while using ".kubeconfig" files for more dyrnamic clusters.
    #
    # BASH COMPLETION
    #   The 'kc' function supports standard bash auto completion, offering
    #   completion for all the kubernetes contexts available from the
    #   configured sources as described above.
    # 
    function kc() {

        if [[ $# -gt 1 || ${1} == 'help' ]]; then
            echo "Usage: kc [<context>|all|-] (no args: show KUBECONFIG)"
            return
        fi

        context=${1}

        if [ -z "${context}" ]; then
            [ "${KUBECONFIG}" == "" ] && echo "KUBECONFIG not set" || echo $KUBECONFIG

        elif [ "${context}" == '-' ]; then
            unset KUBECONFIG

        elif [ "${context}" == 'all' ]; then
            export KUBECONFIG=$(kc_all)

        elif [[ ${context} =~ \.kubeconfig$ ]]; then
            [ -f "${HOME}/.kube/${context}" ] && \
                export KUBECONFIG="${HOME}/.kube/${context}" || \
                echo "error: no kubeconfig exists with the name '${context}'"

        else
            if ! KUBECONFIG=$(kc_all) kubectl config get-contexts --output='name' ${context} &> /dev/null; then
                echo "error: no context exists with the name '${context}'"
                return
            fi

            [ -d "${HOME}/.kube/.kc" ] || mkdir "${HOME}/.kube/.kc"

            KUBECONFIG=$(kc_all) kubectl config view --minify --raw --context ${context} >"${HOME}/.kube/.kc/${context}.kc"

            export KUBECONFIG="${HOME}/.kube/.kc/${context}.kc"
        fi
    }

    function kc_all() {
        local kubeconfig

        [ -f "${HOME}/.kube/config" ] && kubeconfig="${HOME}/.kube/config"

        for f in $(ls ~/.kube/*.kubeconfig); do
            kubeconfig="$kubeconfig:$f"
            kubeconfig=$(echo $kubeconfig | sed 's/^://')
        done

        echo $kubeconfig
    }

    function __kc_completions() {
        local contexts kubeconfigs completions

        if contexts=$(kubectl config --kubeconfig ~/.kube/config get-contexts --output='name' 2>/dev/null); then
            completions=("${contexts[*]}")
            # contexts=("${contexts[*]}")
        fi

        if kubeconfigs=$(ls -1 ~/.kube/*.kubeconfig 2>/dev/null |xargs -n1 -I{} basename "{}"); then
            # echo "foo"
            completions+=("${kubeconfigs[*]}")
            # kubeconfigs=("${kubeconfigs[*]}")
        fi

          # echo "c:${completions[@]}"
          if [ ${#completions[@]} -gt 0 ]; then 
              COMPREPLY=($(compgen -W "${completions[*]}" -- "${COMP_WORDS[1]}"))
          fi
    }

    complete -F __kc_completions kc
fi

# }}}

# History {{{

#
# Intent here is: 
# - Unlimited (or effectively unlimited) history.
# - History from current shell _not_ available to concurrently running shells.
# - History from the current shell available to new shells started while the
# current shell is still active (and after it's closed obviously).
#
# Got most of this from:
#
# https://unix.stackexchange.com/questions/1288/preserve-bash-history-in-multiple-terminal-windows
#
# Note that as the above post mentions, there can be issues with referencing
# commands by number in this scheme.
#

# NOTE!!! Because we're messing with the prompt here, this needs to come before
# the visual prompt modifications we're making (one observed issue was
# powerline-go never showing any errors becuase)

shopt -s histappend

HISTSIZE=5000
HISTFILESIZE=100000
HISTCONTROL=ignorespace:ignoredups:erasedups

# Don't add to history:
# - history commands (really important for csshX)
# - non-arg ls commands
# - echo to base64 or json, which can oftentimes be _really_ long lines (which
#   makes my command recall _very_ slow)
HISTIGNORE='history:history *:h:h *:hl:ls:ll:la:echo *base64*:echo *json_pp*'

history() {
  _bash_history_sync
  builtin history "$@"
}

_bash_history_sync() {
  # Append session history to history file.
  builtin history -a            

  # Resetting HISTFILESIZE will force history file to be truncated to the
  # specified size.  Without this, file will only be truncated when the shell
  # is closed.
  HISTFILESIZE=$HISTFILESIZE    
}

PROMPT_COMMAND="_bash_history_sync;$PROMPT_COMMAND"

# }}}

# Prompt {{{
#
# If powerline-go is installed use it. If not...
# If a brew installation of bash-git-prompt exits, well use that. If not...
# We'll cobble together our own prompt that includes the following:
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
# IMPORTANT! Do this BEFORE the history stuff as that attaches itself to the
# prompt as well.
#

if [ -n "${VIM}" ]; then
    # We're in a VIM shell (i.e. :shell).
    :

elif [[ ! "${PS4}" =~ ^\+[[:space:]]*$ ]]; then
    # We've specifically set PS4, let's not mess it up with PS1.
    :

elif which powerline-go >/dev/null; then

    function _update_ps1() {
        #
        # NOTES
        #   - The default modules are:
        #   nix-shell,venv,user,host,ssh,cwd,perms,git,hg,jobs,exit,root,vgo
        #   - The default theme is 'default' (dark). For dark screen
        #   backgrounds, might want to try 'low-contrast'
        #   - The '-newline' option is good so that command input isn't
        #   constantly jumping around as the length of the prompt grows and
        #   shrinks. The implementation isn't awesome, however. Specifically:
        #       - The '$' in the prompt shows up twice. Once at the end of
        #       the "powerline" and again on the newline. No reason for it to
        #       be in the "powerline" itself.
        #       - The newline, in addition to having the '$', also has the '>'
        #       (as a font symbol) following the '$'. There's no need for that,
        #       but it's actually annoying when it come to copying and pasting
        #       commands as it only shows up as an odd looking artifact.
        #   I'll handle this specifically, by not using '-newline' option and
        #   then sed'ing the prompt to remove the '$' and insert it back after
        #   a newline.
        #
        #   I've since found that it's the "root" module that controls this
        #   behavior. If we remove it, and enable -newline, things are better.
        #   However, there's still the > symbol in front of the $ on the
        #   newline. I think I like my sed option better.
        #

        PS1="$(powerline-go \
               -modules nix-shell,venv,kube,ssh,cwd,perms,git,hg,jobs,exit,root,vgo \
               -error $? \
               |sed -E 's/ \\\$ (.*)$/\1\\n$ /' \
            )"

        # local __DURATION=1
        #
        # PS1="$(powerline-go \
        #        -modules duration,nix-shell,venv,kube,ssh,cwd,perms,git,hg,jobs,exit,root,vgo \
        #        -duration $__DURATION \
        #        -error $? \
        #        |sed -E 's/ \\\$ (.*)$/\1\\n$ /' \
        #     )"
    }

    if [ "$TERM" != "linux" ]; then
        PROMPT_COMMAND="_update_ps1;$PROMPT_COMMAND"
    fi

elif [ -f "/usr/local/opt/bash-git-prompt/share/gitprompt.sh" ]; then
    __GIT_PROMPT_DIR="/usr/local/opt/bash-git-prompt/share"
    GIT_PROMPT_THEME=Solarized
    source "/usr/local/opt/bash-git-prompt/share/gitprompt.sh"

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
