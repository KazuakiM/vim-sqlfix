let s:save_cpo = &cpo
set cpo&vim

"TODO: Rails log message support? I don't know Rails. So I try Rails.
"TODO: Keyword completion
"TODO: Support 1 liner so long

"variable {{{
let g:sqlfix#IndentSize = ! exists('g:sqlfix#IndentSize') ? 4 : g:sqlfix#IndentSize
let s:SqlfixFrameWork   = ! exists('s:SqlfixFrameWork')   ? {
    \ 'Yii': '. Bound with'} :
    \ s:SqlfixFrameWork
let s:SqlfixKeywordsNewLine = ! exists('s:SqlfixKeywordsNewLine') ?  [
    \ 'alter',  'and',    'begin', 'case',   'commit', 'create', 'delete',   'drop',   'else',     'elseif',
    \ 'end',    'from',   'grant', 'group',  'having', 'inner',  'insert',   'left',   'limit',    'lock',
    \ 'on',     'or',     'order', 'rename', 'revoke', 'right',  'rollback', 'select', 'truncate', 'union',
    \ 'unlock', 'update', 'when',  'where'] :
    \ s:SqlfixKeywordsNewLine
let s:SqlfixKeywordsContinue = ! exists('s:SqlfixKeywordsContinue') ? [
    \ 'add',               'after',   'all',      'as',    'asc',    'between', 'by',   'column', 'current_date', 'current_time',
    \ 'current_timestamp', 'desc',    'distinct', 'in',    'index',  'is',      'join', 'key',    'like',         'not',
    \ 'null',              'primary', 'sysdate',  'table', 'tables', 'then',    'unique'] :
    \ s:SqlfixKeywordsContinue
let s:SqlfixKeywordsFunction = ! exists('s:SqlfixKeywordsFunction') ? [
    \ 'abs(',       'acos(',    'ascll(',    'asin(',      'atan(',     'atan2(',        'avg(',          'ceiling(',    'char(',     'char_length(',
    \ 'concat(',    'cos(',     'cot(',      'count(',     'date_add(', 'date_format(',  'date_sub(',     'dayofmonth(', 'dayname(',  'dayofweek(',
    \ 'dayofyear(', 'degrees(', 'exp(',      'floor(',     'greatest(', 'group_concat(', 'hour(',         'if(',         'ifnull(',   'initcap(',
    \ 'insert(',    'inster(',  'last_day(', 'least(',     'left(',     'length(',       'lower(',        'ltrim(',      'max(',      'min(',
    \ 'minute(',    'mod(',     'month(',    'monthname(', 'now(',      'nullif(',       'octet_length(', 'pi(',         'position(', 'pow(',
    \ 'radians(',   'rand(',    'repeat(',   'replace(',   'reverse(',  'right(',        'round(',        'rtrim(',      'second(',   'sign(',
    \ 'sin(',       'sqrt(',    'stddev(',   'substring(', 'sum(',      'tan(',          'time_format(',  'trim(',       'upper(',    'week(',
    \ 'year('] :
    \ s:SqlfixKeywordsFunction
let s:V      = vital#of('sqlfix')
let s:String = s:V.import('Data.String')
let s:Buffer = s:V.import('Vim.Buffer')
"}}}
function! sqlfix#Normal() abort "{{{
    call sqlfix#Fix()
    call append(line('.'), s:SqlfixReturn)
endfunction "}}}
function! sqlfix#Visual() range abort "{{{
    call sqlfix#Fix()
    call append(a:lastline, s:SqlfixReturn)
endfunction "}}}
function! sqlfix#Fix() abort "{{{
    " Init
    let s:SqlfixReturn       = []
    let s:SqlfixCloseBracket = 0
    let s:SqlfixStatus       = []

    " Get last selected
    let l:sqlBody = substitute(s:Buffer.get_last_selected(), '\r\n\|\n\|\r', ' ', 'g')

    " Supported FrameWork
    for l:key in keys(s:SqlfixFrameWork)
        let l:frameWorkIdx = stridx(l:sqlBody, s:SqlfixFrameWork[l:key])
        if l:frameWorkIdx > -1 && l:key is 'Yii'
            let l:frameWorkBinds = split(l:sqlBody[l:frameWorkIdx+13:],',\s\+')
            let l:sqlBody        = l:sqlBody[:l:frameWorkIdx-1]
            for l:frameWorkBind in l:frameWorkBinds
                let l:frameWorkParam = split(l:frameWorkBind, '=')
                if stridx(l:frameWorkParam[0], ':') is -1
                    let l:sqlBody = substitute(l:sqlBody, ':'.l:frameWorkParam[0], l:frameWorkParam[1], 'g')
                else
                    let l:sqlBody = substitute(l:sqlBody,     l:frameWorkParam[0], l:frameWorkParam[1], 'g')
                endif
            endfor
        endif
    endfor
    "PP '['.l:sqlBody.']'

    " Trim
    let l:oldLineLow = ''
    while l:oldLineLow !=# l:sqlBody
        let l:oldLineLow = l:sqlBody
        let l:sqlBody    = s:String.trim(substitute(substitute(substitute(substitute(
            \ l:sqlBody, '(', '( ', 'g'), ')', ' )', 'g'), ',\s\+\|,', ', ', 'g'), '\s\+', ' ', 'g'))
    endwhile
    "PP '['.l:sqlBody.']'

    " Add EndWords
    let l:sqlBodyLen = strlen(l:sqlBody)
    if strpart(l:sqlBody, l:sqlBodyLen -1) isnot ';' && strpart(l:sqlBody, l:sqlBodyLen -2) isnot '\G'
        let l:sqlBody = l:sqlBody.';'
    endif
    "PP '['.l:sqlBody.']'

    " Split word.
    let l:wordBlock    = ''
    let l:splitLineLow = split(l:sqlBody, ' ')
    for l:words in l:splitLineLow
        if count(s:SqlfixKeywordsFunction, l:words, 1) >= 1
            let l:wordBlock = l:wordBlock.' '.toupper(l:words)
            call add(s:SqlfixStatus, 'function')
        elseif stridx(l:words, '(') is 0
            call s:SqlfixAddReturn(l:wordBlock.' '.l:words)
            call add(s:SqlfixStatus, 'bracket')
            let l:wordBlock = ''
        elseif stridx(l:words, ')') > -1
            let l:wordBlock           = l:wordBlock.l:words
            let s:SqlfixCloseBracket -= 1
        elseif count(s:SqlfixKeywordsContinue, l:words, 1) >= 1
            let l:wordBlock = l:wordBlock.' '.toupper(l:words)
        elseif count(s:SqlfixKeywordsNewLine, l:words, 1) >= 1
            if count(s:SqlfixStatus, 'function') + s:SqlfixCloseBracket > 0
                let l:wordBlock = l:wordBlock.' '.toupper(l:words)
            else
                call s:SqlfixAddReturn(l:wordBlock)
                let l:wordBlock = toupper(l:words)
            endif
        else
            let l:wordBlock = l:wordBlock.' '.l:words
        endif
        "echo '['.join(s:SqlfixStatus).': '.s:SqlfixCloseBracket.': '.l:words.': '.l:wordBlock.']'
    endfor
    " Rest wordBlock
    call s:SqlfixAddReturn(l:wordBlock)

    return s:SqlfixReturn
endfunction "}}}
function! s:SqlfixAddReturn(wordBlock) abort "{{{
    if strlen(a:wordBlock) > 0
        let l:indentString = ''
        let l:indentMax    = count(s:SqlfixStatus, 'bracket') * g:sqlfix#IndentSize
        if l:indentMax > 0
            for l:indentIndex in range(l:indentMax)
                let l:indentString = l:indentString.' '
            endfor
        endif

        call add(s:SqlfixReturn, l:indentString.a:wordBlock)
        while s:SqlfixCloseBracket < 0
            call remove(s:SqlfixStatus, -1)
            let s:SqlfixCloseBracket += 1
        endwhile
        "echo '<'.join(s:SqlfixStatus).': '.s:SqlfixCloseBracket.': '.l:indentString.a:wordBlock.'>'
    endif
endfunction "}}}

if exists('s:save_cpo')
    let &cpo = s:save_cpo
    unlet s:save_cpo
endif
