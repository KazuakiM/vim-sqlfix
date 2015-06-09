let s:save_cpo = &cpo
set cpo&vim

"variable {{{
let s:sqlfixReturn      = ! exists('s:sqlfixReturn')      ? [] : s:sqlfixReturn
let s:sqlfixIndentLevel = ! exists('s:sqlfixIndentLevel') ? 0  : s:sqlfixIndentLevel
let s:sqlfixIndentSize  = ! exists('s:sqlfixIndentSize')  ? 4  : s:sqlfixIndentSize

"XXX:Completion words.
let s:sqlfixKeywordsNewLine = ! exists('s:sqlfixKeywordsNewLine') ?
    \ ['and', 'delete', 'from', 'group', 'having', 'inner', 'insert', 'left', 'limit', 'or', 'order', 'right', 'select', 'update', 'where'] :
    \ s:sqlfixKeywordsNewLine
let s:sqlfixKeywordsContinue = ! exists('s:sqlfixKeywordsContinue') ?
    \ ['as', 'between', 'by', 'distinct', 'in', 'is', 'join', 'like', 'not', 'null', 'on'] :
    \ s:sqlfixKeywordsContinue
let s:sqlfixKeywordsFunction = ! exists('s:sqlfixKeywordsFunction') ?
    \ ['avg(', 'concat(', 'count(', 'length(', 'max(', 'min(', 'now(', 'stddev(', 'sum('] :
    \ s:sqlfixKeywordsFunction
"}}}

function! sqlfix#Execute() range abort "{{{
    " Parse words.
    let a:wordBlock = ''
    for a:lineNumber in range(a:firstline, a:lastline)
        " Trim
        let a:oldLineLow = ''
        let a:lineLow  = tolower(getline(a:lineNumber))
        while a:oldLineLow !=# a:lineLow
            let a:oldLineLow = a:lineLow
            let a:lineLow    = substitute(substitute(a:lineLow,  '(', '( ', 'g'), '  ',  ' ', 'g')
        endwhile

        " Split word.
        let a:splitLineLow = split(a:lineLow, ' ')
        for a:words in a:splitLineLow
            if count(s:sqlfixKeywordsNewLine, a:words) >= 1
                call s:sqlfixAddReturn(a:wordBlock)
                let a:wordBlock = toupper(a:words)
            elseif count(s:sqlfixKeywordsContinue, a:words) >= 1
                let a:wordBlock = a:wordBlock.' '.toupper(a:words)
            elseif stridx(a:words, '(') is 0
                call s:sqlfixAddReturn(a:wordBlock.' '.a:words)
                let a:wordBlock          = ''
                let s:sqlfixIndentLevel += 1
            elseif stridx(a:words, ')') > 0
                call s:sqlfixAddReturn(a:wordBlock.' '.a:words)
                let a:wordBlock          = ''
                let s:sqlfixIndentLevel -= 1
            else
                let a:wordBlock = a:wordBlock.' '.a:words
            endif
        endfor
    endfor
    " Rest wordBlock
    call s:sqlfixAddReturn(a:wordBlock)

    " Output
    call append(a:lastline, s:sqlfixReturn)
endfunction "}}}

function! s:sqlfixAddReturn(wordBlock) abort "{{{
    if strlen(a:wordBlock) > 0
        let a:indentString = ''
        let a:indentMax    = s:sqlfixIndentLevel * s:sqlfixIndentSize
        for a:indentIndex in range(a:indentMax)
            let a:indentString = a:indentString.' '
        endfor
        call add(s:sqlfixReturn, a:indentString.a:wordBlock)
    endif
endfunction "}}}

let &cpo = s:save_cpo
unlet s:save_cpo
