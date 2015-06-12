let s:save_cpo = &cpo
set cpo&vim

"TODO: Rails log message support?
"TODO: Test case.
"TODO: Keyword completion

"variable {{{
let s:sqlfixIndentSize  = ! exists('s:sqlfixIndentSize') ? 4 : s:sqlfixIndentSize
let s:sqlfixFrameWork   = ! exists('s:sqlfixFrameWork')  ? {
    \ 'Yii': '. Bound with'} :
    \ s:sqlfixFrameWork
let s:sqlfixKeywordsNewLine = ! exists('s:sqlfixKeywordsNewLine') ?  [
    \ 'alter', 'and', 'begin', 'commit', 'create', 'delete', 'drop',     'from',   'grant',    'group', 'having', 'inner',  'insert', 'left', 'limit', 'lock',
    \ 'on',    'or',  'order', 'rename', 'revoke', 'right',  'rollback', 'select', 'truncate', 'union', 'unlock', 'update', 'where'] :
    \ s:sqlfixKeywordsNewLine
let s:sqlfixKeywordsContinue = ! exists('s:sqlfixKeywordsContinue') ? [
    \ 'all',  'as',  'asc',  'between', 'by',      'current_date', 'current_time', 'current_timestamp', 'desc', 'distinct', 'in', 'index', 'is', 'join', 'key',
    \ 'like', 'not', 'null', 'primary', 'sysdate', 'table',        'tables',       'unique'] :
    \ s:sqlfixKeywordsContinue
let s:sqlfixKeywordsFunction = ! exists('s:sqlfixKeywordsFunction') ? [
    \ 'abs(',          'acos(',   'ascll(',    'asin(',         'atan(',        'atan2(',    'avg(',        'ceiling(', 'char(',      'char_length(', 'concat(',
    \ 'cos(',          'cot(',    'count(',    'date_add(',     'date_format(', 'date_sub(', 'dayofmonth(', 'dayname(', 'dayofweek(', 'dayofyear(',   'degrees(',
    \ 'exp(',          'floor(',  'greatest(', 'group_concat(', 'hour(',        'ifnull(',   'initcap(',    'insert(',  'inster(',    'least(',       'left(',
    \ 'length(',       'lower(',  'ltrim(',    'max(',          'min(',         'minute(',   'mod(',        'month(',   'monthname(', 'now(',         'nullif(',
    \ 'octet_length(', 'pi(',     'position(', 'pow(',          'radians(',     'rand(',     'repeat(',     'replace(', 'reverse(',   'right(',       'round(',
    \ 'rtrim(',        'second(', 'sign(',     'sin(',          'sqrt(',        'stddev(',   'substring(',  'sum(',     'tan(',       'time_format(', 'trim(',
    \ 'upper(',        'week(',   'year('] :
    \ s:sqlfixKeywordsFunction
"}}}
"vital.vim {{{
let s:V      = vital#of('sqlfix')
let s:Buffer = s:V.import('Vim.Buffer')
"}}}
function! sqlfix#Execute() range abort "{{{
    " Init
    let s:sqlfixReturn    = []
    let s:indentLevel     = 0
    let s:indentLevelFlag = 0

    " Get last selected
    let a:sqlBody = substitute(s:Buffer.get_last_selected(), '\n\|\r\|\r\n', ' ', 'g')

    " Supported FrameWork
    for a:key in keys(s:sqlfixFrameWork)
        let a:frameWorkIdx = stridx(a:sqlBody, s:sqlfixFrameWork[a:key])
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
        if count(s:sqlfixKeywordsFunction, a:words, 1) >= 1
            let a:wordBlock      = a:wordBlock.' '.toupper(a:words)
            let a:functionLevel += 1
        elseif stridx(a:words, '(') is 0
            call s:sqlfixAddReturn(a:wordBlock.' '.a:words)
            let a:wordBlock    = ''
            let s:indentLevel += 1
        elseif stridx(a:words, ')') > -1
            let a:wordBlock = a:wordBlock.a:words
            if a:functionLevel > 0
                let a:functionLevel -= 1
            else
                let s:indentLevelFlag = 1
            endif
        elseif count(s:sqlfixKeywordsContinue, a:words, 1) >= 1
            let a:wordBlock = a:wordBlock.' '.toupper(a:words)
        elseif count(s:sqlfixKeywordsNewLine, a:words, 1) >= 1
            if a:functionLevel > 0
                let a:wordBlock = a:wordBlock.' '.toupper(a:words)
            else
                call s:sqlfixAddReturn(a:wordBlock)
                let a:wordBlock = toupper(a:words)
            endif
        else
            let a:wordBlock = a:wordBlock.' '.a:words
        endif
        "echo '['.a:functionLevel.': '.s:indentLevel.': '.s:indentLevelFlag.': '.a:words.': '.a:wordBlock.']'
    endfor
    " Rest wordBlock
    call s:sqlfixAddReturn(a:wordBlock)

    " Output
    call append(a:lastline, s:sqlfixReturn)
endfunction "}}}
function! s:sqlfixAddReturn(wordBlock) abort "{{{
    if strlen(a:wordBlock) > 0
        let a:indentString = ''
        let a:indentMax    = s:indentLevel * s:sqlfixIndentSize
        if a:indentMax > 0
            for a:indentIndex in range(a:indentMax)
                let a:indentString = a:indentString.' '
            endfor
        endif

        call add(s:sqlfixReturn, a:indentString.a:wordBlock)
        if s:indentLevelFlag is 1
            let s:indentLevel     -= 1
            let s:indentLevelFlag  = 0
        endif
        "PP '['.a:indentString.': '.a:wordBlock.']'
    endif
endfunction "}}}

let &cpo = s:save_cpo
unlet s:save_cpo
