source "$mod_fzf_config/.fzf.bash"

fzf-binds() {
        printf 'ctrl-v:execute(less -K {}),'
        printf 'ctrl-e:execute(${EDITOR:-vim} {})+abort,'
        printf 'ctrl-u:execute-silent(xclip -selection clipboard < {}),'
        printf 'ctrl-y:execute-silent(echo {} | xargs echo -n | xclip -selection clipboard),'
        printf 'ctrl-r:execute-silent(realpath {} | xargs echo -n | xclip -selection clipboard)'
}

# export FZF_DEFAULT_OPTS="--bind '$(fzf-binds)'"

# Use ~~ as the trigger sequence instead of the default **
export FZF_COMPLETION_TRIGGER='**'

# Options to fzf command
export FZF_COMPLETION_OPTS='+c -x'

# Use fd (https://github.com/sharkdp/fd) instead of the default find
# command for listing path candidates.
# - The first argument to the function ($1) is the base path to start traversal
# - See the source code (completion.{bash,zsh}) for the details.
# _fzf_compgen_path() {
#   fd --hidden --follow -I --exclude ".git" . "$1"
# }

# # Use fd to generate the list for directory completion
# _fzf_compgen_dir() {
#   fd --type d --hidden -I -follow --exclude ".git" . "$1"
# }

export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude ".git"'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

# full list: complete | grep _fzf
# add:
## complete -F _fzf_path_completion -o default -o bashdefault ag
## complete -F _fzf_dir_completion -o default -o bashdefault tree



fze() {
  about "Open the selected file in the default editor"
  group "fzf"
  param "1: Search term"
  example "fe foo"

  local IFS=$'\n'
  local files
  local query=$(echo $*)
  files=($(fzf-tmux --query "$query" --multi))
  [[ -n "$files" ]] && ${EDITOR:-vim} "${files[@]}"
}

fzd() {
  about "cd to the selected directory"
  group "fzf"
  param "1: Directory to browse, or . if omitted"
  example "fd aliases"

  local dir
  dir=$(find ${1:-.} -path '*/\.*' -prune \
                  -o -type d -print 2> /dev/null | fzf +m) &&
  cd "$dir"
}

fzfasg() {
  about "Use fasd to search the file to open in vim"
  group "fzf"
  param "1: Search term for fasd"
  example "vf xml"

      local query=$(echo $*)
  files=($(fasd -Rfl "$@" | fzf --query "$query" --no-sort --multi))
  [[ -n "$files" ]] && ${EDITOR:-vim} "${files[@]}"

}

fzfasf() {
  about "Use fasd to search the file to open in vim"
  group "fzf"
  param "1: Search term for fasd"
  example "vf xml"

      local query=$(echo $*)
  files=($(fasd -Rfl $@ | fzf --query "$query" --no-sort --multi))
  [[ -n "$files" ]] && ${EDITOR:-vim} "${files[@]}"

}

fzfasd() {
  about "Use fasd to search the file to open in vim"
  group "fzf"
  param "1: Search term for fasd"
  example "vf xml"
  
  local query=$(echo $*)
  files=($(fasd -Rdl $@ | fzf --query "$query" --no-sort))
  [[ -n "$files" ]] && cd "$files"

}

fzfprev() {
## Try highlight, coderay, rougify in turn, then fall back to cat
  fzf --preview '[[ $(file --mime {}) =~ binary ]] &&
                 echo {} is a binary file ||
                 (highlight -O ansi -l {} ||
                  coderay {} ||
                  rougify {} ||
                  cat {}) 2> /dev/null | head -500'
}




acad () {
    local DIR open
    declare -A already
    DIR="${HOME}/.cache/pdftotext"
    mkdir -p "${DIR}"
    if [ "$(uname)" = "Darwin" ]; then
        open=open
    else
        open="gio open"
    fi

    {
    ag -g ".pdf$"; # fast, without pdftotext
    ag -g ".pdf$" \
    | while read -r FILE; do
        local EXPIRY HASH CACHE
        HASH=$(md5sum "$FILE" | cut -c 1-32)
        # Remove duplicates (file that has same hash as already seen file)
        [ ${already[$HASH]+abc} ] && continue # see https://stackoverflow.com/a/13221491
        already[$HASH]=$HASH
        EXPIRY=$(( 86400 + $RANDOM * 20 )) # 1 day (86400 seconds) plus some random
        CMD="pdftotext -f 1 -l 1 '$FILE' - 2>/dev/null | tr \"\n\" \"_\" "
        CACHE="$DIR/$HASH"
        test -f "${CACHE}" && [ $(expr $(date +%s) - $(date -r "$CACHE" +%s)) -le $EXPIRY ] || eval "$CMD" > "${CACHE}"
        echo -e "$FILE\t$(cat ${CACHE})"
    done
    } | fzf -e  -d '\t' \
        --preview-window up:75% \
        --preview '
                v=$(echo {q} | tr " " "|");
                echo {1} | grep -E "^|$v" -i --color=always;
                pdftotext -f 1 -l 1 {1} - | grep -E "^|$v" -i --color=always' \
        | awk 'BEGIN {FS="\t"; OFS="\t"}; {print "\""$1"\""}' \
        | xargs $open > /dev/null 2> /dev/null
}


chr() {
  local cols sep google_history open
  cols=$(( COLUMNS / 3 ))
  sep='{::}'

  if [ "$(uname)" = "Darwin" ]; then
    google_history="$HOME/Library/Application Support/Google/Chrome/Default/History"
    open=open
  else
    google_history="$HOME/.config/google-chrome/Default/History"
    open=xdg-open
  fi
  cp -f "$google_history" /tmp/h
  sqlite3 -separator $sep /tmp/h \
    "select substr(title, 1, $cols), url
     from urls order by last_visit_time desc" |
  awk -F $sep '{printf "%-'$cols's  \x1b[36m%s\x1b[m\n", $1, $2}' |
  fzf --ansi --multi | sed 's#.*\(https*://\)#\1#' | xargs $open > /dev/null 2> /dev/null
}





# misc

# fkill - kill process
fzkill() {
  local pid
  pid=$(ps -ef | sed 1d | fzf -m | awk '{print $2}')

  if [ "x$pid" != "x" ]
  then
    echo $pid | xargs kill -${1:-9}
  fi
}

# git -------


# fshow - git commit browser
fzgshow() {
  git log --graph --color=always \
      --format="%C(auto)%h%d %s %C(black)%C(bold)%cr" "$@" |
  fzf --ansi --no-sort --reverse --tiebreak=index --bind=ctrl-s:toggle-sort \
      --bind "ctrl-m:execute:
                (grep -o '[a-f0-9]\{7\}' | head -1 |
                xargs -I % sh -c 'git show --color=always % | less -R') << 'FZF-EOF'
                {}
FZF-EOF"
}

# fstash - easier way to deal with stashes
# type fstash to get a list of your stashes
# enter shows you the contents of the stash
# ctrl-d shows a diff of the stash against your current HEAD
# ctrl-b checks the stash out as a branch, for easier merging
fzgstash() {
  local out q k sha
  while out=$(
    git stash list --pretty="%C(yellow)%h %>(14)%Cgreen%cr %C(blue)%gs" |
    fzf --ansi --no-sort --query="$q" --print-query \
        --expect=ctrl-d,ctrl-b);
  do
    mapfile -t out <<< "$out"
    q="${out[0]}"
    k="${out[1]}"
    sha="${out[-1]}"
    sha="${sha%% *}"
    [[ -z "$sha" ]] && continue
    if [[ "$k" == 'ctrl-d' ]]; then
      git diff $sha
    elif [[ "$k" == 'ctrl-b' ]]; then
      git stash branch "stash-$sha" $sha
      break;
    else
      git stash show -p $sha
    fi
  done
}

# fcs - get git commit sha
# example usage: git rebase -i `fcs`
fzgsha() {
  local commits commit
  commits=$(git log --color=always --pretty=oneline --abbrev-commit --reverse) &&
  commit=$(echo "$commits" | fzf --tac +s +m -e --ansi --reverse) &&
  echo -n $(echo "$commit" | sed "s/ .*//")
}

# fcoc - checkout git commit
fzgcoc() {
  local commits commit
  commits=$(git log --pretty=oneline --abbrev-commit --reverse) &&
  commit=$(echo "$commits" | fzf --tac +s +m -e) &&
  git checkout $(echo "$commit" | sed "s/ .*//")
}

# fco_preview - checkout git branch/tag, with a preview showing the commits between the tag/branch and HEAD
fzgco_prev() {
  local tags branches target
  tags=$(
git tag | awk '{print "\x1b[31;1mtag\x1b[m\t" $1}') || return
  branches=$(
git branch --all | grep -v HEAD |
sed "s/.* //" | sed "s#remotes/[^/]*/##" |
sort -u | awk '{print "\x1b[34;1mbranch\x1b[m\t" $1}') || return
  target=$(
(echo "$tags"; echo "$branches") |
    fzf --no-hscroll --no-multi --delimiter="\t" -n 2 \
        --ansi --preview="git log -200 --pretty=format:%s $(echo {+2..} |  sed 's/$/../' )" ) || return
  git checkout $(echo "$target" | awk '{print $2}')
}


# fbr - checkout git branch (including remote branches)
fzgco() {
  local branches branch
  branches=$(git branch --all | grep -v HEAD) &&
  branch=$(echo "$branches" |
           fzf-tmux -d $(( 2 + $(wc -l <<< "$branches") )) +m) &&
  git checkout $(echo "$branch" | sed "s/.* //" | sed "s#remotes/[^/]*/##")
}
