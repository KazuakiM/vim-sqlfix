let s:save_cpo = &cpo
set cpo&vim

"TODO: Rails log message support? I don't know Rails. So I try Rails.
"TODO: Keyword completion
"TODO: Support 1 liner so long
"TODO: Required END semicolon check.

"variable {{{
let s:SqlfixIndentSize  = ! exists('s:SqlfixIndentSize') ? 4 : s:SqlfixIndentSize
let s:SqlfixFrameWork   = ! exists('s:SqlfixFrameWork')  ? {
    \ 'Yii': '. Bound with'} :
    \ s:SqlfixFrameWork
let s:SqlfixKeywordsNewLine = ! exists('s:SqlfixKeywordsNewLine') ?  [
    \ 'alter', 'and', 'begin', 'commit', 'create', 'delete', 'drop',     'from',   'grant',    'group', 'having', 'inner',  'insert', 'left', 'limit', 'lock',
    \ 'on',    'or',  'order', 'rename', 'revoke', 'right',  'rollback', 'select', 'truncate', 'union', 'unlock', 'update', 'where'] :
    \ s:SqlfixKeywordsNewLine
let s:SqlfixKeywordsContinue = ! exists('s:SqlfixKeywordsContinue') ? [
    \ 'all',  'as',  'asc',  'between', 'by',      'current_date', 'current_time', 'current_timestamp', 'desc', 'distinct', 'in', 'index', 'is', 'join', 'key',
    \ 'like', 'not', 'null', 'primary', 'sysdate', 'table',        'tables',       'unique'] :
    \ s:SqlfixKeywordsContinue
let s:SqlfixKeywordsFunction = ! exists('s:SqlfixKeywordsFunction') ? [
    \ 'abs(',          'acos(',   'ascll(',    'asin(',         'atan(',        'atan2(',    'avg(',        'ceiling(', 'char(',      'char_length(', 'concat(',
    \ 'cos(',          'cot(',    'count(',    'date_add(',     'date_format(', 'date_sub(', 'dayofmonth(', 'dayname(', 'dayofweek(', 'dayofyear(',   'degrees(',
    \ 'exp(',          'floor(',  'greatest(', 'group_concat(', 'hour(',        'ifnull(',   'initcap(',    'insert(',  'inster(',    'least(',       'left(',
    \ 'length(',       'lower(',  'ltrim(',    'max(',          'min(',         'minute(',   'mod(',        'month(',   'monthname(', 'now(',         'nullif(',
    \ 'octet_length(', 'pi(',     'position(', 'pow(',          'radians(',     'rand(',     'repeat(',     'replace(', 'reverse(',   'right(',       'round(',
    \ 'rtrim(',        'second(', 'sign(',     'sin(',          'sqrt(',        'stddev(',   'substring(',  'sum(',     'tan(',       'time_format(', 'trim(',
    \ 'upper(',        'week(',   'year('] :
    \ s:SqlfixKeywordsFunction
"}}}
"vital.vim {{{
let s:Buffer = vital#of('sqlfix').import('Vim.Buffer')
"}}}
function! Sqlfix#Normal() abort "{{{
    call Sqlfix#Fix()
    call append(line('.'), s:SqlfixReturn)
endfunction "}}}
function! Sqlfix#Visual() range abort "{{{
    call Sqlfix#Fix()
    call append(a:lastline, s:SqlfixReturn)
endfunction "}}}
function! Sqlfix#Fix() abort "{{{
    " Init
    let s:SqlfixReturn    = []
    let s:indentLevel     = 0
    let s:indentLevelFlag = 0

    " Get last selected
    let a:sqlBody = substitute(s:Buffer.get_last_selected(), '\r\n\|\n\|\r', ' ', 'g')

    " Supported FrameWork
    for a:key in keys(s:SqlfixFrameWork)
        let a:frameWorkIdx = stridx(a:sqlBody, s:SqlfixFrameWork[a:key])
        if a:frameWorkIdx > -1 && a:key is 'Yii'
            let a:frameWorkBinds = split(a:sqlBody[a:frameWorkIdx+13:],',\s\+')
            let a:sqlBody        = a:sqlBody[:a:frameWorkIdx-1]
            for a:frameWorkBind in a:frameWorkBinds
                let a:frameWorkParam = split(a:frameWorkBind, '=')
                if stridx(a:frameWorkParam[0], ':') is -1
                    let a:sqlBody = substitute(a:sqlBody, ':'.a:frameWorkParam[0], a:frameWorkParam[1], 'g')
                else
                    let a:sqlBody = substitute(a:sqlBody,     a:frameWorkParam[0], a:frameWorkParam[1], 'g')
                endif
            endfor
        endif
    endfor
    "PP '['.a:sqlBody.']'

    " Trim
    let a:oldLineLow = ''
    while a:oldLineLow !=# a:sqlBody
        let a:oldLineLow = a:sqlBody
        let a:sqlBody    = substitute(substitute(substitute(substitute(a:sqlBody, '(', '( ', 'g'), ')', ' )', 'g'), ',\s\+\|,', ', ', 'g'), '\s\+', ' ', 'g')
    endwhile
    "PP '['.a:sqlBody.']'

    " Split word.
    let a:functionLevel   = 0
    let a:wordBlock       = ''
    let a:splitLineLow    = split(a:sqlBody, ' ')
    for a:words in a:splitLineLow
        if count(s:SqlfixKeywordsFunction, a:words, 1) >= 1
            let a:wordBlock      = a:wordBlock.' '.toupper(a:words)
            let a:functionLevel += 1
        elseif stridx(a:words, '(') is 0
            call s:SqlfixAddReturn(a:wordBlock.' '.a:words)
            let a:wordBlock    = ''
            let s:indentLevel += 1
        elseif stridx(a:words, ')') > -1
            let a:wordBlock = a:wordBlock.a:words
            if a:functionLevel > 0
                let a:functionLevel -= 1
            else
                let s:indentLevelFlag = 1
            endif
        elseif count(s:SqlfixKeywordsContinue, a:words, 1) >= 1
            let a:wordBlock = a:wordBlock.' '.toupper(a:words)
        elseif count(s:SqlfixKeywordsNewLine, a:words, 1) >= 1
            if a:functionLevel > 0
                let a:wordBlock = a:wordBlock.' '.toupper(a:words)
            else
                call s:SqlfixAddReturn(a:wordBlock)
                let a:wordBlock = toupper(a:words)
            endif
        else
            let a:wordBlock = a:wordBlock.' '.a:words
        endif
        "echo '['.a:functionLevel.': '.s:indentLevel.': '.s:indentLevelFlag.': '.a:words.': '.a:wordBlock.']'
    endfor
    " Rest wordBlock
    call s:SqlfixAddReturn(a:wordBlock)

    return s:SqlfixReturn
endfunction "}}}
function! s:SqlfixAddReturn(wordBlock) abort "{{{
    if strlen(a:wordBlock) > 0
        let a:indentString = ''
        let a:indentMax    = s:indentLevel * s:SqlfixIndentSize
        if a:indentMax > 0
            for a:indentIndex in range(a:indentMax)
                let a:indentString = a:indentString.' '
            endfor
        endif

        call add(s:SqlfixReturn, a:indentString.a:wordBlock)
        if s:indentLevelFlag is 1
            let s:indentLevel     -= 1
            let s:indentLevelFlag  = 0
        endif
        "PP '['.a:indentString.': '.a:wordBlock.']'
    endif
endfunction "}}}

let &cpo = s:save_cpo
unlet s:save_cpo
