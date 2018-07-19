# for legaczy reasons - this is the stuff that gets whipped with fzf and normally resides within $HOME

PATH_add "$mod_fzf_sw/bin"

# Auto-completion
# ---------------
[[ $- == *i* ]] && source "$mod_fzf_sw/shell/completion.bash" 2> /dev/null

# Key bindings
# ------------
source "$mod_fzf_sw/shell/key-bindings.bash"

