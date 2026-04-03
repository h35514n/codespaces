#!/usr/bin/env bash

set -euo pipefail

SOURCE="${BASH_SOURCE[0]}"

while [ -L "$SOURCE" ]; do
  DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"
  SOURCE="$(readlink "$SOURCE")"
  [[ "$SOURCE" != /* ]] && SOURCE="$DIR/$SOURCE"
done

REPO_ROOT="$(cd -P "$(dirname "$SOURCE")" && pwd)"

#------------------------------------------------------------- 
# CONVENIENCE FUNCTIONS
#-------------------------------------------------------------
md() {
  local directory_name="${*// /-}"
  mkdir -p "${directory_name}"
  cd "${directory_name}" || return
}

#-------------------------------------------------------------
# PROMPT
#-------------------------------------------------------------
declare -A fg_no_bold
fg_no_bold[red]='\[\e[31m\]'
fg_no_bold[yellow]='\[\e[33m\]'
fg_no_bold[green]='\[\e[32m\]'
fg_no_bold[magenta]='\[\e[35m\]'
fg_no_bold[blue]='\[\e[34m\]'
fg_no_bold[white]='\[\e[37m\]'
fg_no_bold[gray]='\[\e[90m\]'
fg_no_bold[orange]='\[\e[38;5;208m\]'
reset_color='\[\e[0m\]'

color() {
  case "$1" in
    red)    printf '%s' "${fg_no_bold[red]}" ;;
    yellow) printf '%s' "${fg_no_bold[yellow]}" ;;
    green)  printf '%s' "${fg_no_bold[green]}" ;;
    violet) printf '%s' "${fg_no_bold[magenta]}" ;;
    blue)   printf '%s' "${fg_no_bold[blue]}" ;;
    orange) printf '%s' "${fg_no_bold[orange]}" ;;
    white)  printf '%s' "${fg_no_bold[white]}" ;;
    gray)   printf '%s' "${fg_no_bold[gray]}" ;;
    reset)  printf '%s' "${reset_color}" ;;
  esac
}

git_color() {
  local git_status
  git_status="$(git status 2>/dev/null)" || return

  case "${git_status}" in
    *'not staged'* | *'to be committed'* | *'untracked files present'* | \
    *'no rastreados'* | *'archivos sin seguimiento'* | *'a ser confirmados'*)
      printf '%s' "$(color red)"
      ;;
    *'branch is ahead of'* | *'have diverged'* | \
    *'rama está adelantada'* | *'rama está detrás de'* | *'han divergido'*)
      printf '%s' "$(color yellow)"
      ;;
    *'working '*' clean'* | *'está limpio'*)
      printf '%s' "$(color green)"
      ;;
    *'Unmerged'* | *'no fusionadas'* | *'rebase interactivo en progreso'*)
      printf '%s' "$(color violet)"
      ;;
    *)
      printf '%s' "$(color white)"
      ;;
  esac
}

git_branch() {
  local git_status
  git_status="$(git status 2>/dev/null)" || return

  local is_on_branch='^(On branch|En la rama) ([^[:space:]]+)'
  local is_on_commit='HEAD \(detached at|desacoplada en\) ([^[:space:]]+)'
  local is_rebasing="(rebasing branch|rebase de la rama) '([^[:space:]]+)' (on|sobre) '([^[:space:]]+)'"
  local branch
  local commit

  if [[ ${git_status} =~ ${is_on_branch} ]]; then
    branch="${BASH_REMATCH[2]}"
    if [[ ${git_status} =~ (Unmerged paths|no fusionadas) ]]; then
      printf '%smerging into %s ' "$(git_color)" "${branch}"
    else
      printf '%s%s ' "$(git_color)" "${branch}"
    fi
  elif [[ ${git_status} =~ ${is_on_commit} ]]; then
    commit="${BASH_REMATCH[2]}"
    printf '%s%s ' "$(git_color)" "${commit}"
  elif [[ ${git_status} =~ ${is_rebasing} ]]; then
    branch="${BASH_REMATCH[2]}"
    commit="${BASH_REMATCH[4]}"
    printf '%srebasing %s onto %s ' "$(git_color)" "${branch}" "${commit}"
  fi
}

git_prompt() {
  local prompt=''

  if [[ -n "${SSH_CONNECTION}" ]]; then
    prompt+="$(color gray)\u@\h$(color reset)\n"
  fi

  if [[ -z "${VIRTUAL_ENV}" && -z "${CONDA_PROMPT_MODIFIER}" ]]; then
    prompt+="$(color blue)\W$(color reset) "
  else
    prompt+="$(color orange)\W$(color reset) "
  fi

  prompt+="$(git_branch)"
  prompt+="$(color reset)\$ "

  PS1="${prompt}"
}

PROMPT_COMMAND=git_prompt

#-------------------------------------------------------------
# ENV vars
#-------------------------------------------------------------
export EDITOR="vim"
export LESS=' --no-init --RAW-CONTROL-CHARS --quit-if-one-screen '  # Less options: no init, raw chars, quit if one screen
export PAGER="less"

export FZF_DEFAULT_OPTS="
  --no-multi
  --exact
  --tiebreak=index
  --color='bg:#1d1e20,bg+:#1d1e20,preview-bg:#1d1e20,border:#1d1e20'
  --bind='ctrl-f:preview-down'
  --bind='ctrl-b:preview-up'
"
export FZF_DEFAULT_COMMAND="fd --hidden --type f --exclude .git --exclude node_modules"
export FZF_CTRL_T_COMMAND="${FZF_DEFAULT_COMMAND}"

#-------------------------------------------------------------
# PATH
#-------------------------------------------------------------
PATH="${HOME}/.bin"
PATH+=":${HOME}/.bin/git"
PATH+=":${HOME}/miniconda3/bin"
PATH+=":${HOME}/miniconda3/condabin"
PATH+=":/usr/local/sbin"
PATH+=":/usr/local/bin"
PATH+=":/usr/sbin"
PATH+=":/usr/bin"
PATH+=":/sbin"
PATH+=":/bin"
PATH+=":/usr/games"
PATH+=":/usr/local/games"
PATH+=":/snap/bin"

#-------------------------------------------------------------
# ALIASES
#-------------------------------------------------------------
alias ..='cd ..; l'         # Go to parent directory and list contents
alias ...='cd ../..; l'     # Go to grandparent directory and list contents
alias mkdir='mkdir -p'      # Create directories recursively
alias h='history'           # Show command history
alias dirs='dirs -v'        # Show directory stack with indices
alias ls='eza --group-directories-first --time-style=long-iso --classify'  # Modern ls replacement with grouping and classification
alias l='ls'                # Short alias for ls
alias la='ls -a'            # List all files (including hidden)
alias ld='ls -d .*'         # List hidden directories only
alias ll='ls -l'            # Long listing
alias lla='ls -al'          # Long listing including hidden
alias lld='ls -al -d .*'    # Long listing of hidden files/directories
alias lt='eza --tree --level=3'  # Tree view up to 3 levels

# 2.2 Safeguards
# alias rm='trash'            # Move to trash instead of deleting
alias mv='mv -i'            # Prompt before overwriting on move
alias cp='cp -i'            # Prompt before overwriting on copy
alias ln='ln -iv'           # Verbose linking with error if link exists

alias pp='pretty-print-path'  # Pretty-print PATH variable

#-------------------------------------------------------------
# SHELL CONFIG
#-------------------------------------------------------------
bind '"\e[A": history-search-backward'
bind '"\e[B": history-search-forward'

#-------------------------------------------------------------
# INIT SCRIPTS
#-------------------------------------------------------------
. "${REPO_ROOT}/scripts/fzf-completion-init"
