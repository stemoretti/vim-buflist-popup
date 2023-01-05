" Description: public interface

" Function: #list {{{1
function! buflist_popup#list() abort
    return copy(buflist_popup#internal#buflist())
endfunction

" Function: #size {{{1
function! buflist_popup#size() abort
    return len(buflist_popup#internal#buflist())
endfunction

" Function: #at {{{1
function! buflist_popup#at(index) abort
    if a:index >= 0 && a:index < buflist_popup#size()
        return copy(buflist_popup#internal#buflist()[a:index])
    endif
    return 0
endfunction

" Function: #index_of {{{1
function! buflist_popup#index_of(arg) abort
    let buflist = copy(buflist_popup#internal#buflist())
    if type(a:arg) == v:t_number
        return index(map(buflist, {_, v -> v.bufnr}), a:arg)
    elseif type(a:arg) == v:t_string
        return index(map(buflist, {_, v -> v.name}), a:arg)
    endif
    return -1
endfunction

" Function: #alternate_bufnr {{{1
function! buflist_popup#alternate_bufnr() abort
    return buflist_popup#internal#alternate()
endfunction

" Function: #get_current_index {{{1
function! buflist_popup#get_current_index() abort
    return buflist_popup#internal#get_index()
endfunction
"}}}

" vim: et sw=4
