" local settings {{{1
silent! setlocal buftype=nofile
silent! setlocal bufhidden=hide
silent! setlocal noswapfile
silent! setlocal nobuflisted

silent! setlocal cursorline
silent! setlocal number
silent! setlocal nowrap
silent! setlocal statusline=
silent! setlocal signcolumn=no
" }}}1

" key mappings {{{1
nnoremap <silent> <buffer> <F1> :call ex#search#toggle_help()<CR>
nnoremap <silent> <buffer> <ESC> :call ex#search#close_window()<CR>
nnoremap <silent> <buffer> <Space> :call ex#search#toggle_zoom()<CR>
nnoremap <silent> <buffer> <CR> :call ex#search#confirm_select('')<CR>
nnoremap <silent> <buffer> <2-LeftMouse> :call ex#search#confirm_select('')<CR>
nnoremap <silent> <buffer> <S-CR> :call ex#search#confirm_select('shift')<CR>
nnoremap <silent> <buffer> <S-2-LeftMouse> :call ex#search#confirm_select('shift')<CR>
nnoremap <silent> <buffer> <leader>r :call ex#search#filter(@/, 'pattern', 0)<CR>
nnoremap <silent> <buffer> <leader>fr :call ex#search#filter(@/, 'file', 0)<CR>
nnoremap <silent> <buffer> <leader>d :call ex#search#filter(@/, 'pattern', 1)<CR>
nnoremap <silent> <buffer> <leader>fd :call ex#search#filter(@/, 'file', 1)<CR>
" }}}1

" auto command {{{1
command! -buffer -nargs=1 R call ex#search#filter('<args>', 'pattern', 0)
command! -buffer -nargs=1 FR call ex#search#filter('<args>', 'file', 0)
command! -buffer -nargs=1 D call ex#search#filter('<args>', 'pattern', 1)
command! -buffer -nargs=1 FD call ex#search#filter('<args>', 'file', 1)
" }}}1
