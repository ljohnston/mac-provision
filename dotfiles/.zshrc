# Modeline & Notes {{{
# vim: set sw=4 ts=4 sts=4 et tw=79 foldlevel=0 foldmethod=marker foldmarker={{{,}}}:
# }}}

# Profiling {{{
# Haven't done any profiling yet, but this might be a good link:
# https://kevin.burke.dev/kevin/profiling-zsh-startup-time/
# https://medium.com/@jzelinskie/please-dont-ship-binaries-with-shell-completion-as-commands-a8b1bcb8a0d0
# PROFILE_STARTUP=true
# if [[ "$PROFILE_STARTUP" == true ]]; then
#     # http://zsh.sourceforge.net/Doc/Release/Prompt-Expansion.html
#     PS4=$'%D{%M%S%.} %N:%i> '
#     exec 3>&2 2>$HOME/tmp/startlog.$$
#     setopt xtrace prompt_subst
# fi
# }}}

# General {{{

#
# In general, keep PATH mods up front in case others rely on them.
#

if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi

if [ -d "/usr/local/sbin" ] ; then
    PATH="/usr/local/sbin:$PATH"
fi

if [[ $OSTYPE == *darwin* ]]; then
    if which brew &>/dev/null; then
        fpath+="$(brew --prefix)/share/zsh/site-functions"

        # We'll make sure that /usr/local/bin is first in our PATH to ensure our
        # brew installed packages will take precedence.  Is there a better way to
        # do this?
        # path=$(echo $PATH \
        #     |sed -E 's|^/usr/local/bin:||' \
        #     |sed -E 's|:/usr/local/bin$||' \
        #     |sed -E 's|:?/usr/local/bin:|:|' \
        #     |sed -E 's|:/usr/local/bin:?|:|')
        # PATH="/usr/local/bin:${path}"
    fi
fi

#
# A python app installed in a virtual env, for example...
#
#   $ source venv/bin/activate
#   $ python3 setup.py install
#
# ... will have a script (at least one) at `venv/bin/<binary>`.
# This will be an entirely self-contained script capable of
# running within it's associated virtual environment. This
# function will link that script so that it's on the path.
#
venv_script() {
    if [ $# -ne 1 ]; then
        echo "Usage: venv_script <path_to_script>"
        return
    fi

    script=${1}

    if [ ! -f $script ]; then
        echo "venv script '$script' not found"
        return
    fi

    if [ ! -d "$HOME/bin" ]; then
        echo "$HOME/bin does not exist"
        return
    fi

    link=$HOME/bin/$(basename $script)

    if [ -f $link ]; then
        echo "$link already exists"
        return
    fi

    ln -s $(realpath $script) $link
    hash -r
}

export CLICOLOR=1
export EDITOR=vim

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
alias hfl='cat $HISTFILE |less'

if which vagrant &>/dev/null; then
    alias vup='vagrant up'
    alias vd='vagrant destroy'
    alias vdf='vagrant destroy --force'
    alias vp='vagrant provision'
    alias vssh='vagrant ssh'
    alias vst='vagrant status'
    alias vsnap='vagrant snapshot'
fi

if which mvim &>/dev/null; then
    alias e='mvim --remote-slient'
fi

alias decode_url='python -c '\''print(input().replace("+", " ").replace("%", "\\x").encode().decode("unicode_escape"))'\'' <<< '

# }}}

# {{{ History

#
# I want:
# - Unlimited (or effectively unlimited) history.
# - History from current shell _not_ available to concurrently running shells.
# - History from the current shell available to new shells started while the
#   current shell is still active (and after it's closed obviously).
#

HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=100000

HISTORY_IGNORE='(history|history *|h|h *|hfg|hfg *|hg|hg *|hl|hfl|echo *base64*|echo *json_pp*)'

setopt incappendhistory          # Write to the history file immediately, not when the shell exits. 
setopt histignoredups            # Don't record an entry that was just recorded again.
setopt histignorealldups         # Delete old recorded entry if new entry is a duplicate.
setopt histfindnodups            # Do not display a line previously found.
setopt histignorespace           # Don't record an entry starting with a space.
setopt histreduceblanks          # Remove superfluous blanks before recording entry.

unsetopt sharehistory            # Don't share history between all sessions.

# 'history' in zsh only shows the last 16 lines... fix it.
alias history='history 1'

# }}}

# History Grep {{{

# NOTE: Since I started using fzf, these aren't so useful anymore.

# History grep that builds up final command to grep for multiple
# items in the command history.
# Usage: hg <string> <string> <string> ...

hg() {
    local cmd
    for i in "$@"; do
      if [[ -z $cmd ]]; then
        cmd="history |grep $i |grep -v '^[0-9]\+ \+hf\?g '"
      else
        cmd="$cmd | grep $i"
      fi
    done
    eval $cmd
}

hfg() {
    local cmd
    for i in "$@"; do
      if [[ -z $cmd ]]; then
        cmd="cat $HISTFILE |grep $i |grep -v '^hf\?g '"
      else
        cmd="$cmd |grep $i"
      fi
    done
    eval $cmd
}

# }}}

# Prompt {{{

if [ -n "${VIM}" ]; then
    # We're in a VIM shell (i.e. :shell from VIM).
    :
elif which starship &>/dev/null; then
    eval "$(starship init zsh)"
fi

# }}}

# {{{ zsh
# This section needs to come after prompt customizations or there seems to be
# some potential for strange behavior (e.g. starship prompt will disable any
# widgets added to 'add-zle-hook-widget').

ZPLUGINDIR=$HOME/.zsh/plugins

if [ -f "$ZPLUGINDIR/zsh_unplugged/zsh_unplugged.zsh" ]; then
    source "$ZPLUGINDIR/zsh_unplugged/zsh_unplugged.zsh"

    repos=(
        zdharma-continuum/fast-syntax-highlighting
        zsh-users/zsh-completions
    )

    plugin-load $repos

    # Turn off syntax highlighting on paste.
    zle_highlight=('paste:none')
fi

MY_SITE_FUNCTIONS=$HOME/.zsh/site-functions

fpath=( $MY_SITE_FUNCTIONS "${fpath[@]}" )

# Initialize completion.
autoload -Uz compinit && compinit -u

# Unbind stupid default keymaps.
bindkey -r '^L'   # clear screen

zstyle ':completion:*' menu selectzmodload zsh/complist

# zsh/complist gives us access to the 'menuselect' keymap.
zmodload zsh/complist
bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'l' vi-forward-char
bindkey -M menuselect 'j' vi-down-line-or-history

setopt rmstarsilent                    # Don't confirm 'rm -rf *'
setopt +o nomatch                      # Don't complain about non-matched globs

# }}}

# {{{ vim mode 

# Found this at:  https://github.com/softmoth/zsh-vim-mode/blob/master/zsh-vim-mode.plugin.zsh
# Might be useful...
#     autoload -Uz surround
#     zle -N delete-surround surround
#     zle -N change-surround surround
#     zle -N add-surround surround
#     vim-mode-bindkey vicmd  -- change-surround cs
#     vim-mode-bindkey vicmd  -- delete-surround ds
#     vim-mode-bindkey vicmd  -- add-surround    ys
#     vim-mode-bindkey visual -- add-surround    S

# vi command line editing
bindkey -v

# For some reason, the vicmd keymap defaults these to up/down-line-or-history,
# which leaves the cursor at the end of the line (very annoying).
bindkey -a k vi-up-line-or-history
bindkey -a j vi-down-line-or-history

# This is mapped to vi-backward-delete-char which you would think would be
# correct. The problem is that in zsh's vi mode, deleting chars after entering
# insert mode will only allow you to delete chars entered while _in_ that
# insert mode session.
bindkey "^?" backward-delete-char

_vi_history_search_backward() {
    zle vi-history-search-backward
    zle vi-beginning-of-line
}

_vi_repeat_search() {
    zle vi-repeat-search
    zle vi-beginning-of-line
}

_vi_rev_repeat_search() {
    zle vi-rev-repeat-search
    zle vi-beginning-of-line
}

zle -N _vi_history_search_backward
zle -N _vi_repeat_search
zle -N _vi_rev_repeat_search

bindkey -M vicmd "/" _vi_history_search_backward
bindkey -M vicmd "n" _vi_repeat_search
bindkey -M vicmd "N" _vi_rev_repeat_search

# }}}

# Tool environments {{{

# This must come _after_ brew PATH manipulations.
if which asdf &>/dev/null; then

    # The asdf installed groovy assumes that your managing java with
    # asdf as well. But I'm not. This will disable that stupid behavior.
    export ASDF_GROOVY_DISABLE_JAVA_HOME_EXPORT=true

    # Recent versions of asdf installed via homebrew seem to be broken.
    # This should fix it for now. See here: 
    #
    #   https://github.com/asdf-vm/asdf/issues/785#issuecomment-2645900454
    
    # source $(brew --prefix asdf)/libexec/asdf.sh
    export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"

    function __asdf_complete() {
        local pluginName="${1}"
        shift

        local currentVersion
        currentVersion="$(asdf current "${pluginName}" |awk '{print $2}')"

        local loadedCompletionName="_ASDF_COMPLETE_${pluginName}_VER"
        # echo $loadedCompletionName
        # echo ${(P)loadedCompletionName}

        if [[ ${(P)loadedCompletionName} != "${currentVersion}" ]]; then
            _asdf_load_completion
            printf -v "${loadedCompletionName}" "%s" "${currentVersion}" 
        fi

        _asdf_complete "${@}"
    }
fi

# Helm
which helm &>/dev/null && source <(helm completion zsh)

# Fzf

if which fzf &>/dev/null; then

    [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

    _fzf_history_file() {
        selection=$(cat $HISTFILE |fzf --no-sort --tac --exact) 
        if [ -n "$selection" ]; then
            BUFFER=$selection
            zle vi-cmd-mode
        fi
    }

    zle -N _fzf_history_file

    #
    # This is bizarre... I want to map ctrl+/ to fzf history. After doing so
    # however, '^/' didn't work at all, but it _did_ output the the string
    # '^_'. I guessed that's what the mapping needs and that works. 
    #
    # In a terminal, ctrl+v followed by ctrl+/ will also output '^_'. I guess
    # that's how we can see what the key binding needs.
    #
    # This following binding _also_ maps '^_', but that's not an issue.
    #

    bindkey '^_' _fzf_history_file

fi
# }}}

# Kubernetes Tooling {{{

if which kubectl &>/dev/null; then

    #
    # Got the following from here: https://github.com/asdf-vm/asdf/issues/752
    #
    
    function _asdf_complete_kubectl() {

        _asdf_complete() {
            # NOTE: _kubectl comes from 'source <(kubectl completion zsh)'
            _kubectl "${@}"
        }

        _asdf_load_completion() {
            source <(kubectl completion zsh)

            #
            # I don't entirely understand how zsh leverages bash completions,
            # but it turns out for this to work the way it should, I need to
            # use the "complete" function here instead to compdef. I figured
            # this out by opening a new shell, running the "source ..." shown
            # above and then did:
            #
            #   $ echo -E $_comps[kubectl]
            #   _bash_complete -o default -F __start_kubectl
            #
            # In addition, I ran:
            #
            #   $ kubectl completion zsh |less
            #
            # Looking at the above output, there's a bunch of bash stuff,
            # including the use of "complete ..." as I'm now using here.
            #
            
            compdef _asdf_complete_kubectl kubectl
        }

        __asdf_complete "kubectl" "${@}"
    }

    compdef _asdf_complete_kubectl kubectl

    alias k='kubectl'
    compdef k=kubectl

    #
    # NOTE: kubectx comes with completion functions for itself and kubens that
    # must be manually installed via symlinks.
    #

    if which kubectx &>/dev/null; then
    
        local ASDF_KUBECTX=$(asdf where kubectx)
        
        local reload_completions=false

        if [ ! ${ASDF_KUBECTX}/completion/_kubectx.zsh -ef ${MY_SITE_FUNCTIONS}/_kubectx.zsh ]; then
            ln -sf ${ASDF_KUBECTX}/completion/_kubectx.zsh ${MY_SITE_FUNCTIONS}/_kubectx.zsh 
            reload_completions=true
        fi

        if [ ! ${ASDF_KUBECTX}/completion/_kubens.zsh -ef ${MY_SITE_FUNCTIONS}/_kubens.zsh ]; then
            ln -sf ${ASDF_KUBECTX}/completion/_kubens.zsh ${MY_SITE_FUNCTIONS}/_kubens.zsh 
            reload_completions=true
        fi

    #     # Calling compinit to load completions for a single completion file
    #     # seems pretty heavyweight. If there is a better way, however, I
    #     # haven't found it yet.
        [ "${reload_completions}" == true ] && compinit

        alias kx='kubectx'
        compdef kx=kubectx

        alias kn='kubens' 
        compdef kn=kubens
    fi

    #
    # FUNCTION
    #   kc
    #
    # DESC
    #   Manage the KUBECONFIG environment variable.
    #
    # USAGE
    #   kc [<context>|ls|all|-]
    #   
    #   where:
    #     <context> dynamically generates a <context>-specific
    #               kubeconfig file and sets KUBECONFIG accordingly
    #     ls        lists all configured contexts and kubeconfigs
    #     all       sets KUBECONFIG to all available configs (see 
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
    #   while using ".kubeconfig" files for more dynamic clusters.
    #
    # BASH COMPLETION
    #   The 'kc' function supports standard zsh auto completion, offering
    #   completion for all the kubernetes contexts available from the
    #   configured sources as described above.
    # 
    function kc() {

        if [[ $# -gt 1 || ${1} == '-h' || ${1} == '--help' || ${1} == 'help' ]]; then
            echo "Usage: kc [<context>|ls|all|-] (no args: show KUBECONFIG)"
            return
        fi

        context=${1}

        if [ -z "${context}" ]; then
            [ "${KUBECONFIG}" = "" ] && echo "KUBECONFIG not set" || echo $KUBECONFIG

        elif [ "${context}" = '-' ]; then
            unset KUBECONFIG

        elif [ "${context}" = 'all' ]; then
            export KUBECONFIG=$(__kc_all)

        elif [ "${context}" = 'ls' ]; then
            local contexts kubeconfigs
            contexts=$(__kc_configcontexts)
            kubeconfigs=$(__kc_kubeconfigs)

            echo '~/.kube/config:'
            if [ -n "${contexts}" ]; then
                for c in $(echo $contexts | tr ' ' '\n' |sort); do 
                    echo "    ${c}"; 
                done
            else
                echo '    <none>'
            fi

            echo '~/.kube/*.kubeconfig:'
            if [ -n "${kubeconfigs}" ]; then
                for k in $(echo $kubeconfigs | tr ' ' '\n' |sort); do 
                    echo "    ${k}"; 
                done
            else
                echo '    <none>'
            fi

        elif [[ ${context} =~ \.kubeconfig$ ]]; then
            [ -f "${HOME}/.kube/${context}" ] && \
                export KUBECONFIG="${HOME}/.kube/${context}" || \
                echo "error: no kubeconfig exists with the name '${context}'"

        # Important that we protect ourselves from 'kc --ls' or such,
        # as this won't error on 'kubectl config get-contexts ...' used
        # below and will actually set a goofy context that doesn't exist.
        elif [[ "${context}" =~ ^- ]]; then
            echo "Illegal argument: ${context} (try --help ?)"

        else
            if ! KUBECONFIG=$(__kc_all) kubectl config get-contexts --output='name' ${context} &> /dev/null; then
                echo "error: no context exists with the name '${context}'"
                return
            fi

            [ -d "${HOME}/.kube/.kc" ] || mkdir "${HOME}/.kube/.kc"

            KUBECONFIG=$(__kc_all) kubectl config view --minify --raw --context ${context} >"${HOME}/.kube/.kc/${context}.kc"

            # Keep some tooling (helm) from griping about kube config file perms.
            chmod 600 "${HOME}/.kube/.kc/${context}.kc"

            export KUBECONFIG="${HOME}/.kube/.kc/${context}.kc"
        fi
    }

    function __kc_all() {
        local kubeconfig

        [ -f "${HOME}/.kube/config" ] && kubeconfig="${HOME}/.kube/config"

        for f in $(ls ~/.kube/*.kubeconfig 2>/dev/null); do
            kubeconfig="$kubeconfig:$f"
            kubeconfig=$(echo $kubeconfig | sed 's/^://')
        done

        echo $kubeconfig
    }

    function __kc_configcontexts() {
        echo $(kubectl config --kubeconfig ~/.kube/config get-contexts --output='name' 2>/dev/null)
    }

    function __kc_kubeconfigs() {
        # Used to use the 'ls -1 ...' command here, but noticed that if there
        # were no '*.kubeconfig' files in '~/.kube' the completsions would
        # include all the files in the current working directory. For some
        # reason using 'find ...' doesn't do the same. Weird.
        # echo $(ls -1 ~/.kube/*.kubeconfig 2>/dev/null |xargs -n1 -I{} basename "{}")
        echo $(find ~/.kube -maxdepth 1 -name '*.kubeconfig' |xargs -n1 -I{} basename "{}")
    }

    _kc() {
        compadd $(__kc_configcontexts) $(__kc_kubeconfigs)

        # This also works in place of the above 'compadd ...'.
        # _arguments '*: :($(__kc_configcontexts) $(__kc_kubeconfigs))'
    }

    compdef _kc kc
fi

# }}}

# Local Config {{{

[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

# }}}

# SDKMAN (has to be last) {{{

if [ -f "$HOME/.sdkman/bin/sdkman-init.sh" ]; then
    export SDKMAN_DIR="$HOME/.sdkman"
    [[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
fi

# }}}
