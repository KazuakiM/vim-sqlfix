let s:save_cpo = &cpo
set cpo&vim

"variable {{{
let s:SqlfixDefaultConfig = ! exists('s:SqlfixDefaultConfig') ? {
    \ 'database': 'mysql', 'indent': 4, 'width': 180, 'explain': 0, 'output': 1, 'direcotry_path': ''} : s:SqlfixDefaultConfig
let s:SqlfixQuickrunConfig = ! exists('s:SqlfixQuickrunConfig') ? {
    \ 'mysql': {     'type': 'sql/mysql',    'command': 'mysql', 'exec': '%c %o < '},
    \ 'postgresql': {'type': 'sql/postgres', 'command': 'psql',  'exec': '%c %o -f '}} : s:SqlfixQuickrunConfig
let s:SqlfixFrameWork       = ! exists('s:SqlfixFrameWork')       ? {'Yii': '. Bound with'} : s:SqlfixFrameWork
let s:SqlfixKeywordsNewLine = ! exists('s:SqlfixKeywordsNewLine') ? [
    \ 'alter',    'and',
    \ 'begin',
    \ 'commit',   'create',
    \ 'delete',   'drop',
    \ 'else',     'elseif', 'end',
    \ 'from',
    \ 'grant',    'group',
    \ 'having',
    \ 'inner',    'insert',
    \ 'left',     'limit',  'lock',
    \ 'on',       'or',     'order',
    \ 'rename',   'revoke', 'right',  'rollback',
    \ 'select',
    \ 'truncate',
    \ 'union',    'unlock', 'update',
    \ 'when',     'where'] : s:SqlfixKeywordsNewLine
let s:SqlfixKeywordsContinue = ! exists('s:SqlfixKeywordsContinue') ? [
    \ 'add',     'after',        'all',          'as',                'asc',
    \ 'by',
    \ 'column',  'current_date', 'current_time', 'current_timestamp',
    \ 'desc',    'distinct',
    \ 'in',      'index',        'is',
    \ 'join',
    \ 'key',
    \ 'like',
    \ 'not',     'null',
    \ 'primary',
    \ 'sysdate',
    \ 'table',   'tables',       'then',
    \ 'unique'] : s:SqlfixKeywordsContinue
let s:save_fileformat_code = ! exists('s:save_fileformat_code') ? (&fileformat is# 'unix') ? "\n" : (&fileformat is# 'mac') ? "\r" : "\r\n" : s:save_fileformat_code
let s:V = ! exists('s:V') ? vital#of('sqlfix').load('Data.List', 'Data.String', 'Vim.Buffer') : s:V
"}}}

function! sqlfix#Normal() abort "{{{
    let l:config = extend(extend({}, exists('g:sqlfix#Config') ? g:sqlfix#Config : {}, 'force'), s:SqlfixDefaultConfig, 'keep')

    call sqlfix#Fix(l:config)
    call s:SqlfixOutput(l:config, line('.'))
endfunction "}}}

function! sqlfix#Visual() range abort "{{{
    let l:config = extend(extend({}, exists('g:sqlfix#Config') ? g:sqlfix#Config : {}, 'force'), s:SqlfixDefaultConfig, 'keep')

    call sqlfix#Fix(l:config)
    call s:SqlfixOutput(l:config, a:lastline)
endfunction "}}}

function! sqlfix#NormalFile() abort "{{{
    let l:config        = extend(extend({}, exists('g:sqlfix#Config') ? g:sqlfix#Config : {}, 'force'), s:SqlfixDefaultConfig, 'keep')
    let l:config.output = 0

    call sqlfix#Fix(l:config)
    call s:SqlfixOutput(l:config, line('.'))
endfunction "}}}

function! sqlfix#VisualFile() range abort "{{{
    let l:config        = extend(extend({}, exists('g:sqlfix#Config') ? g:sqlfix#Config : {}, 'force'), s:SqlfixDefaultConfig, 'keep')
    let l:config.output = 0

    call sqlfix#Fix(l:config)
    call s:SqlfixOutput(l:config, a:lastline)
endfunction "}}}

function! sqlfix#Fix(config) abort "{{{
    " Init
    let s:SqlfixReturn       = ''
    let s:SqlfixCloseBracket = 0
    let s:SqlfixStatus       = []

    " Get last selected
    let l:sqlBody = s:V.Vim.Buffer.get_last_selected()

    " Backup escape string
    let l:escapeList  = []
    let l:escapeIndex = 0
    let l:oldLineLow  = ''
    while l:oldLineLow != l:sqlBody
        let l:oldLineLow = l:sqlBody
        call add(l:escapeList, substitute(matchstr(l:sqlBody, "'[^'']*'"), '&', '\\&', 'g'))
        let l:sqlBody = substitute(l:sqlBody, "'[^'']*'", '___sqlfix'. l:escapeIndex, '')
        let l:escapeIndex += 1
    endwhile
    "PP '['.l:sqlBody.': Binding..'.join(l:escapeList) .']'

    " Delete newline
    let l:sqlBody = substitute(l:sqlBody, '\r\n\|\n\|\r', ' ', 'g')

    " Supported FrameWork
    for l:key in keys(s:SqlfixFrameWork)
        let l:frameWorkIdx = stridx(l:sqlBody, s:SqlfixFrameWork[l:key])
        if -1 < l:frameWorkIdx && l:key ==? 'Yii'
            let l:frameWorkBinds = reverse(s:V.Data.List.sort_by(split(l:sqlBody[l:frameWorkIdx+13:], ',\s\+'), 'strlen(v:val)'))
            let l:sqlBody        = l:sqlBody[:l:frameWorkIdx-1]
            for l:frameWorkBind in l:frameWorkBinds
                let l:frameWorkParam = split(l:frameWorkBind, '=')
                if stridx(l:frameWorkParam[0], ':') is# -1
                    let l:sqlBody = substitute(l:sqlBody, ':'. l:frameWorkParam[0], l:frameWorkParam[1], 'g')
                else
                    let l:sqlBody = substitute(l:sqlBody,      l:frameWorkParam[0], l:frameWorkParam[1], 'g')
                endif
            endfor
        endif
    endfor
    "PP '['.l:sqlBody.']'

    " Trim
    let l:oldLineLow = ''
    while l:oldLineLow != l:sqlBody
        let l:oldLineLow = l:sqlBody
        let l:sqlBody    = s:V.Data.String.trim(substitute(substitute(substitute(substitute(substitute(
            \ l:sqlBody, '(', '( ', 'g'), ')', ' )', 'g'), '(\s\*\s)', '(*)', 'g'), ',\s\+\|,', ', ', 'g'), '\s\+', ' ', 'g'))
    endwhile
    "PP '['.l:sqlBody.']'

    " Add Explain
    if a:config.explain is# 1
        if a:config.database ==? 'postgresql'
            call s:SqlfixAddReturn('EXPLAIN ANALYZE', a:config.indent)
        else
            call s:SqlfixAddReturn('EXPLAIN',         a:config.indent)
        endif
    endif

    " Get EndWords
    let l:sqlEndWords = ';'
    let l:sqlBodyLen  = strlen(l:sqlBody)
    if strpart(l:sqlBody, l:sqlBodyLen -1) is ';'
        let l:sqlBody = l:sqlBody[0:-2]
    elseif strpart(l:sqlBody, l:sqlBodyLen -2) is '\G'
        let l:sqlBody = l:sqlBody[0:-3]
        let l:sqlEndWords = '\G'
    endif
    "PP '['.l:sqlBody.']'

    " Split word.
    let l:wordBlock = ''
    for l:words in split(l:sqlBody, ' ')
        if -1 < match(l:words, '\w(')
            let l:wordBlock = s:SqlfixCheckWordBlockSpaceExist(l:wordBlock, l:words, 1)
            "Supported '(*)' case.
            if stridx(l:words, ')') is# -1
                call add(s:SqlfixStatus, 'function')
            endif

        elseif stridx(l:words, '(') is# 0
            call s:SqlfixAddReturn(s:SqlfixCheckWordBlockSpaceExist(l:wordBlock, l:words, 0), a:config.indent)
            call add(s:SqlfixStatus, 'bracket')
            let l:wordBlock = ''

        elseif -1 < stridx(l:words, ')')
            let l:wordBlock           = l:wordBlock . l:words
            let s:SqlfixCloseBracket -= 1

        elseif l:words is 'case'
            call s:SqlfixAddReturn(l:wordBlock, a:config.indent)
            call add(s:SqlfixStatus, 'bracket')
            let l:wordBlock = toupper(l:words)

        elseif l:words is 'end'
            call s:SqlfixAddReturn(l:wordBlock, a:config.indent)
            let l:wordBlock           = toupper(l:words)
            let s:SqlfixCloseBracket -= 1

        elseif l:words is 'between'
            let l:wordBlock = s:SqlfixCheckWordBlockSpaceExist(l:wordBlock, l:words, 1)
            call add(s:SqlfixStatus, 'row_line')

        elseif 1 <= count(s:SqlfixKeywordsContinue, l:words, 1)
            let l:wordBlock = s:SqlfixCheckWordBlockSpaceExist(l:wordBlock, l:words, 1)

        elseif 1 <= count(s:SqlfixKeywordsNewLine, l:words, 1)
            if 0 < count(s:SqlfixStatus, 'function') + s:SqlfixCloseBracket
                let l:wordBlock = s:SqlfixCheckWordBlockSpaceExist(l:wordBlock, l:words, 1)
            else
                call s:SqlfixAddReturn(l:wordBlock, a:config.indent)
                let l:wordBlock = toupper(l:words)
            endif

        elseif a:config.width isnot -1 && a:config.width < len(l:wordBlock .' '. l:words) && strpart(l:words, strlen(l:words) -1) is# ','
            call s:SqlfixAddReturn(s:SqlfixCheckWordBlockSpaceExist(l:wordBlock, l:words, 0), a:config.indent)
            let l:wordBlock = ''

        else
            let l:wordBlock = s:SqlfixCheckWordBlockSpaceExist(l:wordBlock, l:words, 0)
        endif
        "echo '['.join(s:SqlfixStatus).': '.s:SqlfixCloseBracket.': '.l:words.': '.l:wordBlock.']'
    endfor

    " Add EndWords
    let l:wordBlock = l:wordBlock . l:sqlEndWords

    " Rest wordBlock
    call s:SqlfixAddReturn(l:wordBlock, a:config.indent)

    " Check bracket.
    if s:SqlfixCloseBracket < 0 || 0 < len(s:SqlfixStatus)
        call s:SqlfixWarning(['[WARNING]Would you check a close bracket?',
            \ 'REST:'. join(s:SqlfixStatus) .', COUNT:'. s:SqlfixCloseBracket, 'SQL:'. l:wordBlock])
    endif

    " Return escape string
    let l:escapeIndex = 0
    for l:escapeRow in l:escapeList
        let s:SqlfixReturn = substitute(s:SqlfixReturn, '___sqlfix'. l:escapeIndex, l:escapeRow, '')
        let l:escapeIndex += 1
    endfor
    "echo '['. s:SqlfixReturn .']'

    return s:SqlfixReturn
endfunction "}}}

function! s:SqlfixCheckWordBlockSpaceExist(wordBlock, words, toupper) abort "{{{
    if len(a:wordBlock) is# 0
        if a:toupper
            return toupper(a:words)
        else
            return a:words
        endif
    elseif a:toupper
        return a:wordBlock.' '.toupper(a:words)
    endif
    return a:wordBlock.' '.a:words
endfunction "}}}

function! s:SqlfixAddReturn(wordBlock, indent) abort "{{{
    if 0 < strlen(a:wordBlock)
        if 0 < len(s:SqlfixStatus) && 0 < count(s:SqlfixStatus, 'row_line')
            let s:SqlfixReturn = s:SqlfixReturn . repeat(' ', count(s:SqlfixStatus, 'bracket') * a:indent) . a:wordBlock .' '
            while 0 < count(s:SqlfixStatus, 'row_line')
                call remove(s:SqlfixStatus, -1)
            endwhile
        else
            let s:SqlfixReturn = s:SqlfixReturn . repeat(' ', count(s:SqlfixStatus, 'bracket') * a:indent) . a:wordBlock . s:save_fileformat_code
        endif

        while s:SqlfixCloseBracket < 0
            if 0 < len(s:SqlfixStatus)
                call remove(s:SqlfixStatus, -1)
            else
                call s:SqlfixWarning(['[WARNING]Would you check a close bracket?',
                    \ 'REST:'. join(s:SqlfixStatus) .', COUNT:'. s:SqlfixCloseBracket, 'SQL:'. a:wordBlock])
            endif
            let s:SqlfixCloseBracket += 1
        endwhile
        "echo '<'.join(s:SqlfixStatus).': '.s:SqlfixCloseBracket.': '.a:wordBlock.'>'
    endif
endfunction "}}}

function! s:SqlfixOutput(config, position) abort "{{{
    let l:output = split(s:SqlfixReturn, s:save_fileformat_code)

    " Output buffer file
    if a:config.output ==? 1
        call append(a:position, l:output)
    endif

    " Output file
    if isdirectory(a:config.direcotry_path)
        call writefile(l:output, a:config.direcotry_path.'/sqlfix.sql')
    endif
endfunction "}}}

function! sqlfix#Run() abort "{{{
    let l:config = extend(extend({}, exists('g:sqlfix#Config') ? g:sqlfix#Config : {}, 'force'), s:SqlfixDefaultConfig, 'keep')

    if filereadable(l:config.direcotry_path.'/sqlfix.sql') && exists('g:quickrun_config') is# 1 &&
        \ has_key(g:quickrun_config, s:SqlfixQuickrunConfig[l:config.database].type) is# 1 &&
        \ has_key(g:quickrun_config[s:SqlfixQuickrunConfig[l:config.database].type], 'cmdopt') is# 1
        let l:sql = join(readfile(l:config.direcotry_path.'/sqlfix.sql'))
        echo "Please confirm SQL\nconfig\t:". g:quickrun_config[s:SqlfixQuickrunConfig[l:config.database].type].cmdopt ."\nSQL\t:". l:sql ."\n"
        let l:select = confirm('Are you sure?', "&Yes\n&No\n", 2)
        if l:select is 1
            let l:configQuickrunk      = extend(g:quickrun_config[s:SqlfixQuickrunConfig[l:config.database].type], s:SqlfixQuickrunConfig[l:config.database], 'keep')
            let l:configQuickrunk.exec = s:SqlfixQuickrunConfig[l:config.database].exec.l:config.direcotry_path .'/sqlfix.sql'
            call quickrun#run(l:configQuickrunk)
        endif
    else
        call s:SqlfixWarning(["[ERROR]Would you check g:quickrun_config['sql/xxx']['cmdopt'] or ". l:config.direcotry_path .'/sqlfix.sql is readable?'])
    endif
endfunction "}}}

function! s:SqlfixWarning(warningList) abort "{{{
    echohl ErrorMsg
        for l:warning in a:warningList
            echomsg l:warning
        endfor
    echohl None
endfunction "}}}

if exists('s:save_cpo')
    let &cpo = s:save_cpo
    unlet s:save_cpo
endif
