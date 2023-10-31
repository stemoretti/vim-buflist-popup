" Description: internal interface

let s:save_cpo = &cpoptions
set cpoptions&vim

let s:buflist = []
let s:current_index = -1
let s:alternate = -1
let s:numeric_sequence = 0
let s:sort_methods = #{
    \ bufnr: {x, y -> x.bufnr - y.bufnr},
    \ ext:   {x, y -> s:cmp_extension(x, y)},
    \ path:  {x, y -> x.path ==? y.path ? 0 : (x.path >? y.path ? 1 : -1)},
    \ mru:   {x, y -> y.lastused - x.lastused},
    \ name:  {x, y -> s:cmp_name(x, y)},
    \ }
let s:pathsep = exists('+shellslash') ? '\' : '/'

" Function: #init {{{1
function! buflist_popup#internal#init() abort
    let s:buflist = []
    for buf in getbufinfo(#{buflisted: !g:buflist_popup_show_unlisted})
        if ((!g:buflist_popup_show_noname && empty(buf.name))
            \ || s:match_from_list(buf.name, g:buflist_popup_exclude_names))
            continue
        endif
        call add(s:buflist, #{
            \ bufnr: buf.bufnr,
            \ filename: fnamemodify(buf.name, ':t'),
            \ lastused: buf.lastused,
            \ listed: buf.listed,
            \ modified: buf.changed,
            \ path: buf.name,
            \ })
    endfor

    if !len(s:buflist)
        echo 'No buffers'
        return 0
    endif

    let alt = getbufinfo('#')
    if len(alt) && (g:buflist_popup_show_unlisted || alt[0].listed)
        let s:alternate = alt[0].bufnr
    elseif len(s:buflist) > 1
        let s:alternate = sort(copy(s:buflist), s:sort_methods.mru)[1].bufnr
    else
        let s:alternate = -1
    endif

    if has_key(s:sort_methods, g:buflist_popup_sort_method)
        call sort(s:buflist, s:sort_methods[g:buflist_popup_sort_method])
    else
        echoerr 'Invalid sort method: ' .. g:buflist_popup_sort_method
    endif

    " XXX: lastused is only accurate to the second so sometimes buffers
    " end up inverted
    if g:buflist_popup_sort_method == 'mru' && len(s:buflist) > 1
        if s:buflist[0].bufnr != bufnr('%')
            let tmp = s:buflist[0]
            let s:buflist[0] = s:buflist[1]
            let s:buflist[1] = tmp
        endif
        if s:alternate >= 0 && s:buflist[1].bufnr != s:alternate
            let tmp = s:buflist[1]
            let s:buflist[1] = s:buflist[2]
            let s:buflist[2] = tmp
        endif
    endif

    if g:buflist_popup_reverse_order
        call reverse(s:buflist)
    endif

    return 1
endfunction

" Function: #buflist {{{1
function! buflist_popup#internal#buflist() abort
    return s:buflist
endfunction

" Function: #alternate {{{1
function! buflist_popup#internal#alternate() abort
    return s:alternate
endfunction

" Function: #set_index {{{1
function! buflist_popup#internal#set_index(index) abort
    let s:current_index = max([0, min([a:index, len(s:buflist) - 1])])
endfunction

" Function: #get_index {{{1
function! buflist_popup#internal#get_index() abort
    return s:current_index
endfunction

" Function: #add_to_numeric_sequence {{{1
function! buflist_popup#internal#add_to_numeric_sequence(number) abort
    let ret = -1
    if g:buflist_popup_index_from_1
        if s:numeric_sequence == 0 && a:number == 0
            call s:warning_invalid_index(0)
        else
            let s:numeric_sequence = s:numeric_sequence * 10 + a:number
            echo s:numeric_sequence
            if s:numeric_sequence * 10 > len(s:buflist)
                if s:numeric_sequence <= len(s:buflist)
                    let ret = str2nr(s:numeric_sequence - 1)
                else
                    call s:warning_invalid_index(s:numeric_sequence)
                endif
                let s:numeric_sequence = 0
            endif
        endif
    else
        let s:numeric_sequence = s:numeric_sequence * 10 + a:number
        echo s:numeric_sequence
        if s:numeric_sequence == 0 || s:numeric_sequence * 10 > len(s:buflist) - 1
            if s:numeric_sequence < len(s:buflist)
                let ret = str2nr(s:numeric_sequence)
            else
                call s:warning_invalid_index(s:numeric_sequence)
            endif
            let s:numeric_sequence = 0
        endif
    endif
    return ret
endfunction

" Function: #reset_numeric_sequence {{{1
function! buflist_popup#internal#reset_numeric_sequence() abort
    let s:numeric_sequence = 0
    redraw | echo ''
endfunction

" Function: #get_numeric_sequence {{{1
function! buflist_popup#internal#get_numeric_sequence() abort
    return s:numeric_sequence
endfunction

" Function: #formatted_output {{{1
function! buflist_popup#internal#formatted_output() abort
    let names_len = sort(map(copy(s:buflist), {_, v -> len(v.filename)}), 'n')
    let index_len = strlen(len(s:buflist) - (g:buflist_popup_index_from_1 ? 0 : 1))

    let lines = []

    for index in range(len(s:buflist))
        let buf = s:buflist[index]

        let sign = ' '
        if bufnr('%') == buf.bufnr
            let sign = '%'
        elseif s:alternate != -1 && s:alternate == buf.bufnr
            let sign = '#'
        endif

        let listed = buf.listed ? ' ' : 'u'
        let modified = buf.modified ? '+' : ' '

        let name = '[No Name]'
        if !empty(buf.path)
            let name = buf.filename
            if g:buflist_popup_relative_path
                let path = s:file_path_relative_to_dir(buf.path, getcwd())
            else
                let path = s:format_dir(fnamemodify(buf.path, ':p:h'))
            endif
            if g:buflist_popup_shorten_path
                let path = pathshorten(path, g:buflist_popup_shorten_path)
            endif
            if g:buflist_popup_split_path
                let name = printf('%-' .. names_len[-1] .. 's %s', name, path)
            else
                let name = path .. name
            endif
        endif

        let line = printf('%' .. index_len .. 'd%s %s %s %s',
            \ index + (g:buflist_popup_index_from_1 ? 1 : 0),
            \ listed,
            \ sign,
            \ modified,
            \ name)
        call add(lines, line)
    endfor

    return lines
endfunction

" Function: s:warning_invalid_index {{{1
function! s:warning_invalid_index(index) abort
    redraw
    echohl WarningMsg | echo 'Invalid index: ' .. a:index | echohl None
endfunction

" Function: s:cmp_name {{{1
function! s:cmp_name(l, r) abort
    let Cmp = {x, y -> x ==? y ? 0 : (x >? y ? 1 : -1)}
    let cmp = Cmp(a:l.filename, a:r.filename)
    return cmp == 0 ? Cmp(a:l.path, a:r.path) : cmp
endfunction

" Function: s:cmp_extension {{{1
function! s:cmp_extension(l, r) abort
    let left = fnamemodify(a:l.filename, ':e')
    let right = fnamemodify(a:r.filename, ':e')
    if empty(left) && !empty(right) | return -1 | endif
    if !empty(left) && empty(right) | return 1 | endif
    if empty(left) && empty(right) | return s:cmp_name(a:l, a:r) | endif
    return (left ==? right) ? s:cmp_name(a:l, a:r) : (left >? right ? 1 : -1)
endfunction

" Function: s:match_from_list {{{1
function! s:match_from_list(name, list) abort
    for regex in a:list
        if a:name =~ regex
            return 1
        endif
    endfor
    return 0
endfunction

" Function: s:format_dir {{{1
function! s:format_dir(dir) abort
    return a:dir =~ '[\/]$' ? a:dir : a:dir .. s:pathsep
endfunction

" Function: s:file_path_relative_to_dir {{{1
function! s:file_path_relative_to_dir(file, dir) abort
    let BeginsWith = has('win32')
        \ ? {str, prefix -> str[0:len(prefix) - 1] ==? prefix}
        \ : {str, prefix -> str[0:len(prefix) - 1] ==# prefix}

    " XXX: don't handle URLs
    if a:file =~ '://' | return fnamemodify(a:file, ':p:h:') .. '/' | endif

    let head_of_file = s:format_dir(fnamemodify(a:file, ':p:h'))
    let head_of_dir = s:format_dir(fnamemodify(a:dir, ':p:h'))

    if BeginsWith(head_of_file, head_of_dir)
        return '.' .. s:pathsep .. strpart(head_of_file, len(head_of_dir))
    endif
    let updir = '..' .. s:pathsep
    while 1
        let head_of_dir = s:format_dir(fnamemodify(head_of_dir, ':p:h:h'))
        if BeginsWith(head_of_file, head_of_dir)
            " If the root has been reached, return the full path
            if head_of_dir ==? fnamemodify(head_of_dir, ':p:h:h')
                return head_of_file
            endif
            return updir .. strpart(head_of_file, len(head_of_dir))
        endif
        let updir = updir .. '..' .. s:pathsep
    endwhile
endfunction
"}}}

let &cpoptions = s:save_cpo
unlet s:save_cpo

" vim: et sw=4
