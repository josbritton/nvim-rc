function! s:isVars()
    let filepath = expand("%:p")
    if filepath =~ '\v/(group|host)_vars/.*\.ya?ml$' | return 1 | en
    return 0
endfunction
au BufRead,BufNewFile * if s:isVars() | set ft=yaml | en
