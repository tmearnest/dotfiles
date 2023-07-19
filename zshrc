export DOCKER_BUILDKIT=1
export HISTFILE=~/.zsh_history
export HISTORY_IGNORE='fg|d|j'
export HISTSIZE=10000
export KEYTIMEOUT=1
export PAGER="$(which less)"
export PATH=$HOME/.local/bin:$PATH
export SAVEHIST=1000000000
export VISUAL=nvim
export EDITOR=$VISUAL

setopt complete_in_word correct emacs hist_expire_dups_first hist_fcntl_lock hist_lex_words \
    hist_no_store hist_reduce_blanks hist_verify interactive_comments list_rows_first nobeep \
    no_flow_control no_hist_beep no_list_beep pipe_fail prompt_subst rm_star_wait \
    share_history

autoload -Uz add-zsh-hook cdr chpwd_recent_dirs compinit down-line-or-beginning-search \
    edit-command-line up-line-or-beginning-search vcs_info

# Directory history
add-zsh-hook chpwd chpwd_recent_dirs

# Key bindings
unix_ts () { LBUFFER="${LBUFFER}$(timestamp)" }
zle -N unix_ts
bindkey "^T" unix_ts

foreground-nvim() { fg %nvim }
zle -N foreground-nvim
bindkey '^Z' foreground-nvim

bindkey -s "\el" '^E|less' # M-l -> add pipe to less at end of command

zle -N edit-command-line
bindkey "^X^E" edit-command-line

bindkey "\e[3~" delete-char

zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey "\e[A" up-line-or-beginning-search # Up
bindkey "\e[B" down-line-or-beginning-search # Down

# Less configuration

export LESS=-asSrRix8
export LESS_TERMCAP_me=$(tput sgr0)
export LESS_TERMCAP_se=$(tput sgr0)
export LESS_TERMCAP_ue=$(tput sgr0)
export LESS_TERMCAP_mr=$(tput rev)
export LESS_TERMCAP_mh=$(tput dim)
export LESS_TERMCAP_ZN=$(tput ssubm)
export LESS_TERMCAP_ZV=$(tput rsubm)
export LESS_TERMCAP_ZO=$(tput ssupm)
export LESS_TERMCAP_ZW=$(tput rsupm)
export LESS_TERMCAP_mb=$(tput setaf 196)
export LESS_TERMCAP_md=$(tput setaf 111)$(tput bold)
export LESS_TERMCAP_us=$(tput smul)$(tput setaf 51)
export LESS_TERMCAP_so=$(tput setab 220)$(tput setaf 232)

if which src-hilite-lesspipe.sh >/dev/null 2>&1
then
    export LESSOPEN="|src-hilite-lesspipe.sh %s"
fi

# Aliases

alias ls='ls -F --color=auto'
alias l='ls -ltra --color=auto'
alias rm='rm -I'
alias df='df -h -x tmpfs -x squashfs -x devtmpfs -x overlay'
alias grep='grep --color=auto'
alias gitlog="git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset'"
alias vim=nvim
alias vimdiff='nvim -d'
alias mdless='glow -p'

# Functions

timestamp () { date '+%Y%m%d_%H%M%S' }

d () {
    if [ $# -ne 1 ]
    then
        cdr -l
    else
        cdr $1
    fi
}

activate () {
    prvwd=$(pwd)
    oldps1=$PS1
    msg="No venv found"
    unsetopt autopushd

    if [ x"$1" != x ]
    then
        cd "$1"
    fi

    while [ x"$(pwd)" != x/ ]
    do
        if [ -e 'activate' ]
        then
            source activate
            msg="source $(pwd)/activate"
            cd $prvwd
            break
        elif [ -e 'bin/activate' ]
        then
            source bin/activate
            msg="source $(pwd)/bin/activate"
            break
        elif [ -e '.python/bin/activate' ]
        then
            source .python/bin/activate
            msg="source $(pwd)/.python/bin/activate"
            break
        fi
    cd ..
    done

    cd $prvwd
    setopt autopushd
    echo $msg
    export PS1="$oldps1"
    rehash
}

cdve () {
    if [ -z "$VIRTUAL_ENV" ]
    then
        echo "cdve: Not in an activated venv"
        return 1
    else
        cd "$VIRTUAL_ENV"
    fi
}

jsonless () {
    LESS=-SRix4
    jq -C '' <$1 |less
}

j () {
    if [ $# -eq 0 ]; then
        jobs
    else
        fg "%$1"
    fi
}


tmux () {
    if [ "x$TMUX" = "x" ]
    then
        command tmux new-session -t main
    fi
}

pdf_cat () {
    out="$1"
    shift
    gs -dBATCH -dNOPAUSE -q -sDEVICE=pdfwrite -dPDFSETTINGS=/prepress -sOutputFile="$out" $@
}

nbless () {
    if [ $# -ne 1 ]; then
        echo usage: nbless notebook.ipynb
        return -1
    fi

    if [ "$1" = -h ] || [ "$1" = --help ]; then
        echo usage: nbless notebook.ipynb
        return
    fi

    if [ ! -f "$1" ]; then
        echo "nbless: $1: No such file"
        return -1
    fi

    jupyter nbconvert --stdout --to markdown "$1" 2>/dev/null | pygmentize -l md | less
}

to_split ()
{
    cmd="$@; echo; echo Completed at \$(date); cat"
    command tmux split-window -d -v bash -c "$cmd"
}

to_split_forever ()
{
    cmd="while true; do $@; read; done"
    command tmux split-window -d -v bash -c "$cmd"
}

# Prompt data
precmd () {
    vcs_info
    psvar=()
    if (jobs | grep -i '\[[0-9]\+\] \+[-+]\? *suspended' 2>&1 >/dev/null)
    then
        psvar[1]=1 # stopped jobs?
    fi
    if (jobs | grep -i '\[[0-9]\+\] \+[-+]\? *running' 2>&1 >/dev/null)
    then
        psvar[2]=1 # running jobs?
    fi
    psvar[3]="${vcs_info_msg_0_}"
    psvar[4]="${VIRTUAL_ENV}"
}

# VCS prompt config
zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:*' check-for-changes true
zstyle ':vcs_info:*' check-for-staged-changes true

# Tab completion
compinit
eval $(gdircolors)
zstyle ':completion:*' cache-path "~/.zcompcache"
zstyle ':completion:*' complete-options true
zstyle ':completion:*' completer _complete _match _approximate
zstyle ':completion:*' file-sort access reverse
zstyle ':completion:*' group-name ''
zstyle ':completion:*' list-separator "│"
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*' menu yes select search
zstyle ':completion:*' squeeze-slashes true
zstyle ':completion:*' use-cache on
zstyle ':completion:*:approximate:*' max-errors 1 numeric
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS} "ma=48;5;32;1"
zstyle ':completion:*:manuals.*' insert-sections  true
zstyle ':completion:*:manuals' separate-sections true
zstyle ':completion:*:match:*' original only
zstyle ':completion:*:*:kill:*' force-list always
zstyle ':completion:*:*:kill:*' insert-ids single
zstyle ':completion:*:*:kill:*' menu yes select
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;36=0=01'
zstyle ':completion:*:*:*:*:processes' command 'ps -u $LOGNAME -o pid,user,command -w'

# installed packages
source_zsh () { test -e $1 && source $1 }
source_zsh /usr/share/doc/pkgfile/command-not-found.zsh
source_zsh /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
unset -f source_zsh

# Styling
zle_highlight=(isearch:fg=82,underline)
export PROMPT='%F{114}%64<⋯<%~%<<%(!_%F{200}#_%F{226}❯)%f '
export PS2='%F{114}%1_%F{226}❯%f '
export PS3='%F{114}?%F{226}#%f '
export PS4='%F{251}+%F{114}%N%F{239}:%F{251}%i%F{226}❯ %f'
export RPROMPT='%(?__%F{239}ret:%F{251}%? )%(1j_%F{239}jobs%F{239}:%F{251}%j%F{239}(%(1V.%F{166}S.)%(2V.%F{82}R.)%F{239}%) _)%(4V_%F{239}py:%F{140}%4v _)%(3V_%F{239}git:${vcs_info_msg_0_} _)%F{65}%D{%Y-%m-%d %H:%M:%S}'
zstyle ':completion:*:corrections' format '%F{117}%d%F{220} (errors:%e)%f'
zstyle ':completion:*:*:*:*:descriptions' format $'\n''%F{117}━━━━━ %d ━━━━━%f'
zstyle ':completion:*:messages' format '%F{117}%d%f'
zstyle ':completion:*:warnings' format '%F{220}No match: %F{117}%d%f'
zstyle ':vcs_info:*' actionformats '%F{81}%b%c%u%F{239}:%F{160}%a'
zstyle ':vcs_info:*' formats '%F{81}%b%c%u'
zstyle ':vcs_info:*' stagedstr '%F{239}:%F{82}S'
zstyle ':vcs_info:*' unstagedstr '%F{239}:%F{207}U'

source ~/.secrets
