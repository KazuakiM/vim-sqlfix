if &cp || (exists('g:loaded_sqlfix') && g:loaded_sqlfix)
    finish
endif
let g:loaded_sqlfix = 1

command! -nargs=0        Sqlfix               :call sqlfix#Normal()
command! -nargs=0 -range Sqlfix <line1>,<line2>call sqlfix#Visual()
