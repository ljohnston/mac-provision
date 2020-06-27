# Modeline & Notes {{{
# vim: set sw=4 ts=4 sts=4 et tw=79 foldlevel=0 foldmethod=marker foldmarker={{{,}}}:
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

    # If we're running brew, let's make sure that /usr/local/bin is first in
    # our PATH to ensure our brew installed packages will take precedence.
    if which brew &>/dev/null; then
        # Is there a better way to do this?
        path=$(echo $PATH \
            |sed -E 's|^/usr/local/bin:||' \
            |sed -E 's|:/usr/local/bin$||' \
            |sed -E 's|:?/usr/local/bin:|:|' \
            |sed -E 's|:/usr/local/bin:?|:|')
        PATH="/usr/local/bin:${path}"

        # I get hate mail from GitHub if I commit this... do I really need it?
        # export HOMEBREW_GITHUB_API_TOKEN=4f5c0b3fbdc3e00f865bb7850ab947be03ae461f
    fi
fi

export CLICOLOR=1
export EDITOR=vim

# Initialze completion.
autoload -U compinit && compinit
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

# }}}

# Tool environments {{{

# This must come _after_ brew PATH manipulations.
if which asdf &>/dev/null; then

    # The 'asdf.sh' that we just source actually creates `asdf` as a
    # function. Therfore, we can't directly wrap it in a function called
    # `asdf`, so we'll do this little wrapper/alias trick.
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

    # Make asdf completions work with our function.
    compdef asdf_=asdf
fi

# For now, I think jenv is better for java than asdf. Mostly because jenv
# leaves me in control of installing whatever jdks/jres I want and then simply
# telling jenv about them. 
# Of course, I also have sdkman. TODO: Sort this...
which jenv &>/dev/null && eval "$(jenv init -)"

if which pyenv &>/dev/null; then
    function pyenv() {
        echo "Use 'asdf' to manage python versions (via 'python-build')..."
    }
fi

if which rbenv &>/dev/null; then
    function rbenv() {
        echo "Use 'asdf' to manage ruby versions (via 'ruby-build')..."
    }
fi

# I didn't install fzf via brew, but maybe a I should.
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# if which fzf &>/dev/null; then
# hfe() { 
#     output=$(cat ~/.bash_history |fzf --no-sort --tac) && eval $output 
# }
# fi

# }}}

# Kubernetes Tooling {{{
if which kubectl &>/dev/null; then
#
    alias k='kubectl'
    compdef k=kubectl

    if which kubectx &>/dev/null; then
        alias kx='kubectx'
        compdef kx=kubectx
    fi

    if which kubens &>/dev/null; then
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
    #   while using ".kubeconfig" files for more dyrnamic clusters.
    #
    # BASH COMPLETION
    #   The 'kc' function supports standard bash auto completion, offering
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

            export KUBECONFIG="${HOME}/.kube/.kc/${context}.kc"
        fi
    }

    function __kc_all() {
        local kubeconfig

        [ -f "${HOME}/.kube/config" ] && kubeconfig="${HOME}/.kube/config"

        for f in $(ls ~/.kube/*.kubeconfig); do
            kubeconfig="$kubeconfig:$f"
            kubeconfig=$(echo $kubeconfig | sed 's/^://')
        done

        echo $kubeconfig
    }

    function __kc_configcontexts() {
        echo $(kubectl config --kubeconfig ~/.kube/config get-contexts --output='name' 2>/dev/null)
    }

    function __kc_kubeconfigs() {
        echo $(ls -1 ~/.kube/*.kubeconfig 2>/dev/null |xargs -n1 -I{} basename "{}")
    }

    _kc() {
        # TODO: Is there a reason to do all of this as opposed to what's below?
        # local contexts kubeconfigs 
        # local -a completions
        #
        # if contexts=$(__kc_configcontexts); then
        #     completions=("${contexts[*]}")
        # fi
        #
        # if kubeconfigs=$(__kc_kubeconfigs); then
        #     completions+=("${kubeconfigs[*]}")
        # fi
        # compadd $(echo $completions)
        
        compadd $(__kc_configcontexts) $(__kc_kubeconfigs)
    }

    compdef _kc kc
fi

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

setopt incappendhistory          # Write to the history file immediately, not when the shell exits. 
setopt histexpiredupsfirst       # Expire duplicate entries first when trimming history.
setopt histignoredups            # Don't record an entry that was just recorded again.
setopt histignorealldups         # Delete old recorded entry if new entry is a duplicate.
setopt histfindnodups            # Do not display a line previously found.
setopt histignorespace           # Don't record an entry starting with a space.
setopt histsavenodups            # Don't write duplicate entries in the history file.
setopt histreduceblanks          # Remove superfluous blanks before recording entry.

unsetopt sharehistory            # Don't share history between all sessions.

# }}}

# Prompt {{{

if [ -n "${VIM}" ]; then
    # We're in a VIM shell (i.e. :shell).
    :

elif which starship &>/dev/null; then
    eval "$(starship init zsh)"

fi

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

# For some reason, the vicmd keymap defaults these to up/down-line-or-history.
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

# Local Config {{{

[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

# }}}
