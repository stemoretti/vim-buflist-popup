" Description: vim implementation

scriptencoding utf-8

let s:save_cpo = &cpoptions
set cpoptions&vim

let s:winid = 0

let s:border_chars = #{
    \ rounded: ['─', '│', '─', '│', '╭', '╮', '╯', '╰'],
    \ single:  ['─', '│', '─', '│', '┌', '┐', '┘', '└'],
    \ solid:   [' '],
    \ }

" Function: #show {{{1
function! buflist_popup#vim#show() abort
    if s:winid || !buflist_popup#internal#init() | return | endif

    let buflines = buflist_popup#internal#formatted_output()
    let buflines_widths = sort(map(copy(buflines), {_, v -> len(v)}), 'N')

    let opts = #{
        \ drag: 0,
        \ wrap: 0,
        \ callback: 's:buffer_selected',
        \ padding: [0, 0, 0, 0],
        \ filter: 's:key_filter',
        \ maxheight: &lines - 4,
        \ maxwidth: &columns - 4,
        \ minwidth: buflines_widths[-1],
        \ }

    if type(g:buflist_popup_border) == v:t_list
        let opts.borderchars = g:buflist_popup_border
    elseif g:buflist_popup_border == 'none'
        let opts.border = [0, 0, 0, 0]
    elseif has_key(s:border_chars, g:buflist_popup_border)
        let opts.borderchars = s:border_chars[g:buflist_popup_border]
    endif

    let s:winid = popup_menu(buflines, opts)

    if exists('#User#BuflistPopup')
        doautocmd <nomodeline> User BuflistPopup
    endif

    let index = buflist_popup#index_of(bufnr('%'))
    call buflist_popup#vim#select(index >= 0 ? index : 0)

    call buflist_popup#internal#reset_numeric_sequence()
endfunction

" Function: #close {{{1
function! buflist_popup#vim#close() abort
    if !s:winid | return | endif
    call popup_close(s:winid)
    let s:winid = 0
endfunction

" Function: #select {{{1
function! buflist_popup#vim#select(index) abort
    if !s:winid | return | endif
    call buflist_popup#internal#set_index(a:index)
    call win_execute(s:winid,
        \ 'normal! ' .. (buflist_popup#get_current_index() + 1) .. 'G')
    call buflist_popup#internal#reset_numeric_sequence()
endfunction

" Function: #update {{{1
function! buflist_popup#vim#update() abort
    if !s:winid | return | endif
    let index = buflist_popup#get_current_index()
    call buflist_popup#vim#close()
    call buflist_popup#vim#show()
    call buflist_popup#vim#select(index)
endfunction

" Function: #winid {{{1
function! buflist_popup#vim#winid() abort
    return s:winid
endfunction

" Function: s:buffer_selected {{{1
" Used by popup_menu as a callback
function! s:buffer_selected(id, result) abort
    if a:result > 0
        exec 'buffer' buflist_popup#at(a:result - 1).bufnr
    endif
    let s:winid = 0
endfunction

" Function: s:close_switch_to {{{1
function! s:close_switch_to(winid, index) abort
    call popup_close(a:winid, a:index + 1)
    call buflist_popup#internal#reset_numeric_sequence()
    let s:winid = 0
endfunction

" Function: s:key_filter {{{1
function! s:key_filter(winid, key) abort
    if a:key =~ '\d'
        let num = buflist_popup#internal#add_to_numeric_sequence(a:key)
        if num >= 0
            if g:buflist_popup_move_to_index
                call buflist_popup#vim#select(num)
            else
                call s:close_switch_to(a:winid, num)
            endif
        endif
        return 1
    elseif a:key == "\<CR>"
        let num = buflist_popup#internal#get_numeric_sequence()
        if num > 0
            let index = num - (g:buflist_popup_index_from_1 ? 1 : 0)
            if g:buflist_popup_move_to_index
                call buflist_popup#vim#select(index)
            else
                call s:close_switch_to(a:winid, index)
            endif
            return 1
        endif
    elseif a:key == g:buflist_popup_alternate_key
        let alt = buflist_popup#alternate_bufnr()
        if alt >= 0
            call s:close_switch_to(a:winid, buflist_popup#index_of(alt))
            return 1
        endif
    else
        for keymap in g:buflist_popup_mappings
            if a:key == keymap.key && !empty(keymap.exec)
                exec keymap.exec
                return 1
            endif
        endfor
    endif

    call buflist_popup#internal#reset_numeric_sequence()

    let ret = popup_filter_menu(a:winid, a:key)

    call buflist_popup#internal#set_index(getcurpos(a:winid)[1] - 1)

    return ret
endfunction
"}}}

let &cpoptions = s:save_cpo
unlet s:save_cpo

" vim: et sw=4
