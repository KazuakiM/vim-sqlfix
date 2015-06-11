let s:save_cpo = &cpo
set cpo&vim

"TODO: Yii log message support.
"TODO: Rails log message support?
"TODO: Test case.
"TODO: Yii

"variable {{{
let s:sqlfixIndentLevel = ! exists('s:sqlfixIndentLevel') ? 0 : s:sqlfixIndentLevel
let s:sqlfixIndentSize  = ! exists('s:sqlfixIndentSize')  ? 4 : s:sqlfixIndentSize
let s:sqlfixKeywordsNewLine = ! exists('s:sqlfixKeywordsNewLine') ?  [
    \ 'alter', 'and',   'begin',  'commit', 'create', 'delete',   'drop',   'from',     'grant',  'group',  'having', 'inner', 'insert', 'left', 'limit', 'lock',
    \ 'or',    'order', 'rename', 'revoke', 'right',  'rollback', 'select', 'truncate', 'unlock', 'update', 'where'] :
    \ s:sqlfixKeywordsNewLine
let s:sqlfixKeywordsContinue = ! exists('s:sqlfixKeywordsContinue') ? [
    \ 'as',  'asc',  'between', 'by',      'current_date', 'current_time', 'current_timestamp', 'desc', 'distinct', 'in', 'index', 'is', 'join', 'key', 'like',
    \ 'not', 'null', 'on',      'primary', 'sysdate',      'table',        'tables',            'unique'] :
    \ s:sqlfixKeywordsContinue
let s:sqlfixKeywordsFunction = ! exists('s:sqlfixKeywordsFunction') ? [
    \ 'abs(',      'acos(',  'ascll(',    'asin(',     'atan(',        'atan2(',    'avg(',        'ceiling(',     'char(',      'char_length(',  'concat(',
    \ 'cos(',      'cot(',   'count(',    'date_add(', 'date_format(', 'date_sub(', 'dayofmonth(', 'dayname(',     'dayofweek(', 'dayofyear(',    'degrees(',
    \ 'exp(',      'floor(', 'greatest(', 'hour(',     'initcap(',     'insert(',   'inster(',     'least(',       'left(',      'length(',       'lower(',
    \ 'ltrim(',    'max(',   'min(',      'minute(',   'mod(',         'month(',    'monthname(',  'now(',         'nullif(',    'octet_length(', 'pi(',
    \ 'position(', 'pow(',   'radians(',  'rand(',     'repeat(',      'replace(',  'reverse(',    'right(',       'round(',     'rtrim(',        'second(',
    \ 'sign(',     'sin(',   'sqrt(',     'stddev(',   'substring(',   'sum(',      'tan(',        'time_format(', 'trim(',      'upper(',        'week(',
    \ 'year('] :
    \ s:sqlfixKeywordsFunction
"}}}
function! sqlfix#Execute() range abort "{{{
    " Init
    let s:sqlfixReturn = []

    " Parse words.
    let a:lineLow = ''
    for a:lineNumber in range(a:firstline, a:lastline)
        " Trim
        let a:oldLineLow = ''
        let a:nowLineLow = tolower(getline(a:lineNumber))
        while a:oldLineLow !=# a:nowLineLow
            let a:oldLineLow = a:nowLineLow
            let a:nowLineLow = substitute(substitute(substitute(a:nowLineLow, '(', '( ', 'g'), ',\s\+\|,', ', ', 'g'), '\s\+', ' ', 'g')
        endwhile
        let a:lineLow = a:lineLow.a:nowLineLow
    endfor
    "PP '['.expand('<sfile>').':'.a:lineLow.']'

    " Split word.
    let a:functionLevel = 0
    let a:wordBlock     = ''
    let a:splitLineLow  = split(a:lineLow, ' ')
    for a:words in a:splitLineLow
        if count(s:sqlfixKeywordsNewLine, a:words) >= 1
            call s:sqlfixAddReturn(a:wordBlock)
            let a:wordBlock = toupper(a:words)
        elseif count(s:sqlfixKeywordsContinue, a:words) >= 1
            let a:wordBlock = a:wordBlock.' '.toupper(a:words)
        elseif count(s:sqlfixKeywordsFunction, a:words) >= 1
            if a:functionLevel > 0
                let a:wordBlock = a:wordBlock.toupper(a:words)
            else
                let a:wordBlock = a:wordBlock.' '.toupper(a:words)
            endif
            let a:functionLevel += 1
        elseif stridx(a:words, '(') is 0
            call s:sqlfixAddReturn(a:wordBlock.' '.a:words)
            let a:wordBlock          = ''
            let s:sqlfixIndentLevel += 1
        elseif stridx(a:words, ')') > 0
            if a:functionLevel > 0
                let a:wordBlock      = a:wordBlock.a:words
                let a:functionLevel -= 1
            else
                call s:sqlfixAddReturn(a:wordBlock.' '.a:words)
                let a:wordBlock          = ''
                let s:sqlfixIndentLevel -= 1
            endif
        else
            if a:functionLevel > 0
                let a:wordBlock      = a:wordBlock.a:words
                let a:functionLevel -= 1
            else
                let a:wordBlock = a:wordBlock.' '.a:words
            endif
        endif
        "PP '['.expand('<sfile>').':'.a:functionLevel.': '.a:words.': '.a:wordBlock.']'
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
        if a:indentMax > 0
            for a:indentIndex in range(a:indentMax)
                let a:indentString = a:indentString.' '
            endfor
        endif

        "PP '['.expand('<sfile>').':'.a:indentString.': '.a:wordBlock.']'
        call add(s:sqlfixReturn, a:indentString.a:wordBlock)
    endif
endfunction "}}}

let &cpo = s:save_cpo
unlet s:save_cpo
