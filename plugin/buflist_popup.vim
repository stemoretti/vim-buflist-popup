" vim-buflist-popup - Buffer selection menu
" URL: https://github.com/stemoretti/vim-buflist-popup

if exists('g:loaded_buflist_popup')
    finish
endif
let g:loaded_buflist_popup = 1

let g:buflist_popup_alternate_key = get(g:, 'buflist_popup_alternate_key', '_')
let g:buflist_popup_border = get(g:, 'buflist_popup_border', 'double')
let g:buflist_popup_exclude_names = get(g:, 'buflist_popup_exclude_names', ['Buflist_Popup'])
let g:buflist_popup_index_from_1 = get(g:, 'buflist_popup_index_from_1', 0)
let g:buflist_popup_mappings = get(g:, 'buflist_popup_mappings', [])
let g:buflist_popup_move_to_index = get(g:, 'buflist_popup_move_to_index', 0)
let g:buflist_popup_relative_path = get(g:, 'buflist_popup_relative_path', 1)
let g:buflist_popup_reverse_order = get(g:, 'buflist_popup_reverse_order', 0)
let g:buflist_popup_shorten_path = get(g:, 'buflist_popup_shorten_path', 0)
let g:buflist_popup_show_noname = get(g:, 'buflist_popup_show_noname', 1)
let g:buflist_popup_show_unlisted = get(g:, 'buflist_popup_show_unlisted', 0)
let g:buflist_popup_sort_method = get(g:, 'buflist_popup_sort_method', 'bufnr')
let g:buflist_popup_split_path = get(g:, 'buflist_popup_split_path', 0)

if has('nvim')
    nnoremap <silent> <Plug>(BuflistPopupShow) :call buflist_popup#nvim#show()<CR>
    command! -nargs=0 BuflistPopupShow call buflist_popup#nvim#show()
    command! -nargs=0 BuflistPopupClose call buflist_popup#nvim#close()
    command! -nargs=1 BuflistPopupSelect call buflist_popup#nvim#select(<args>)
    command! -nargs=0 BuflistPopupUpdate call buflist_popup#nvim#update()
else
    nnoremap <silent> <Plug>(BuflistPopupShow) :call buflist_popup#vim#show()<CR>
    command! -nargs=0 BuflistPopupShow call buflist_popup#vim#show()
    command! -nargs=0 BuflistPopupClose call buflist_popup#vim#close()
    command! -nargs=1 BuflistPopupSelect call buflist_popup#vim#select(<args>)
    command! -nargs=0 BuflistPopupUpdate call buflist_popup#vim#update()
endif

if !hasmapto('BuflistPopupShow', 'n') && mapcheck('_', 'n') == ''
    nnoremap <silent> _ <Plug>(BuflistPopupShow)
endif

" vim: et sw=4
