" Description: nvim implementation

let s:save_cpo = &cpoptions
set cpoptions&vim

let s:winid = 0
let s:buffer_handle = nvim_create_buf(v:false, v:true)
call nvim_buf_set_name(s:buffer_handle, 'Buflist_Popup')

let s:index_keymaps = []
for index in range(10)
    call add(s:index_keymaps, #{
        \ key: string(index),
        \ exec: ':call <SID>close_switch_or_move_to_input_number(' .. index .. ')',
        \ })
endfor

" Function: #show {{{1
function! buflist_popup#nvim#show() abort
    if s:winid || !buflist_popup#internal#init() | return | endif

    let curbuf = bufnr('%')

    let buflines = buflist_popup#internal#formatted_output()
    let buflines_widths = sort(map(copy(buflines), {_, v -> len(v)}), 'N')

    let width = buflines_widths[-1]
    let height = len(buflines)

    let opts = #{
        \ relative: 'editor',
        \ width: width,
        \ height: height,
        \ col: &columns / 2 - width / 2,
        \ row: &lines / 2 - height / 2,
        \ anchor: 'NW',
        \ border: g:buflist_popup_border,
        \ style: 'minimal',
        \ }
    let s:winid = nvim_open_win(s:buffer_handle, 1, opts)

    setlocal modifiable
    call nvim_buf_set_lines(s:buffer_handle, 0, -1, v:false, buflines)
    setlocal buftype=nofile nobuflisted nomodifiable bufhidden=hide nonumber
        \ cursorline cc=0 nowrap

    let s:keymaps = [
        \ #{key: '<Esc>', exec: ':call buflist_popup#nvim#close()'},
        \ #{key: '<CR>', exec: ':call <SID>close_switch_to_selected()'},
        \ ]

    if !empty(g:buflist_popup_alternate_key)
        call add(s:keymaps, #{
            \ key: g:buflist_popup_alternate_key,
            \ exec: ':call <SID>close_switch_to_alternate()'
            \ })
    endif

    for k in s:keymaps + s:index_keymaps + g:buflist_popup_mappings
        call nvim_buf_set_keymap(
            \ s:buffer_handle,
            \ 'n',
            \ k.key,
            \ empty(k.exec) ? '' : k.exec .. '<CR>',
            \ #{silent: v:true, nowait: v:true, noremap: v:true})
    endfor

    if exists('#User#BuflistPopup')
        doautocmd <nomodeline> User BuflistPopup
    endif

    let index = buflist_popup#index_of(curbuf)
    call buflist_popup#nvim#select(index >= 0 ? index : 0)

    augroup clear_sequence
        au!
        au CursorHold,CursorMoved <buffer> call buflist_popup#internal#reset_numeric_sequence()
    augroup END

    augroup current_selection
        au!
        au CursorMoved <buffer> call buflist_popup#internal#set_index(nvim_win_get_cursor(0)[0] - 1)
    augroup END
endfunction

" Function: #close {{{1
function! buflist_popup#nvim#close() abort
    if !s:winid | return | endif
    for k in s:keymaps
        call nvim_buf_del_keymap(s:buffer_handle, 'n', k.key)
    endfor
    call buflist_popup#internal#reset_numeric_sequence()
    close
    let s:winid = 0
endfunction

" Function: #select {{{1
function! buflist_popup#nvim#select(index) abort
    if !s:winid | return | endif
    call buflist_popup#internal#set_index(a:index)
    " Make sure the first line of the buffer is at the top of the window
    call nvim_win_set_cursor(0, [1, 0])
    call nvim_win_set_cursor(0, [buflist_popup#get_current_index() + 1, 0])
    call buflist_popup#internal#reset_numeric_sequence()
endfunction

" Function: #update {{{1
function! buflist_popup#nvim#update() abort
    if !s:winid | return | endif
    let index = buflist_popup#get_current_index()
    call buflist_popup#nvim#close()
    call buflist_popup#nvim#show()
    call buflist_popup#nvim#select(index)
endfunction

" Function: #buffer_handle {{{1
function! buflist_popup#nvim#buffer_handle() abort
    return s:buffer_handle
endfunction

" Function: #winid {{{1
function! buflist_popup#nvim#winid() abort
    return s:winid
endfunction

" Function: s:close_switch_to_bufnr {{{1
function! s:close_switch_to_bufnr(bufnr) abort
    call buflist_popup#nvim#close()
    exec 'buffer' a:bufnr
endfunction

" Function: s:close_switch_to_alternate {{{1
function! s:close_switch_to_alternate() abort
    let alternate = buflist_popup#alternate_bufnr()
    if alternate >= 0
        call s:close_switch_to_bufnr(alternate)
    endif
endfunction

" Function: s:close_switch_to_index {{{1
function! s:close_switch_to_index(index) abort
    call s:close_switch_to_bufnr(buflist_popup#at(a:index).bufnr)
endfunction

" Function: s:close_switch_or_move_to_input_number {{{1
function! s:close_switch_or_move_to_input_number(key) abort
    let num = buflist_popup#internal#add_to_numeric_sequence(a:key)
    if num >= 0
        if g:buflist_popup_move_to_index
            call buflist_popup#nvim#select(num)
        else
            call s:close_switch_to_index(num)
        endif
    endif
endfunction

" Function: s:close_switch_to_selected {{{1
function! s:close_switch_to_selected() abort
    let num = buflist_popup#internal#get_numeric_sequence()
    if num > 0
        let index = num - (g:buflist_popup_index_from_1 ? 1 : 0)
        if g:buflist_popup_move_to_index
            call buflist_popup#nvim#select(index)
        else
            call s:close_switch_to_index(index)
        endif
    else
        let pos = nvim_win_get_cursor(0)
        call s:close_switch_to_index(pos[0] - 1)
    endif
endfunction
"}}}

let &cpoptions = s:save_cpo
unlet s:save_cpo

" vim: et sw=4
