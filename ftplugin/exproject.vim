" local settings {{{1
silent! setlocal buftype=
silent! setlocal bufhidden=hide
silent! setlocal noswapfile
silent! setlocal nobuflisted

silent! setlocal cursorline
silent! setlocal nonumber
silent! setlocal nowrap
silent! setlocal statusline=
silent! setlocal signcolumn=no

silent! setlocal foldenable
silent! setlocal foldmethod=marker foldmarker={,}
silent! setlocal foldtext=ex#project#foldtext()
silent! setlocal foldminlines=0
" }}}1

" key mappings {{{1
nnoremap <silent> <buffer> <F1> :call ex#project#toggle_help()<CR>
nnoremap <silent> <buffer> <Space> :call ex#project#toggle_zoom()<CR>
nnoremap <silent> <buffer> <CR> :call ex#project#confirm_select('')<CR>
nnoremap <silent> <buffer> <2-LeftMouse> :call ex#project#confirm_select('')<CR>
nnoremap <silent> <buffer> <S-CR> :call ex#project#confirm_select('shift')<CR>
nnoremap <silent> <buffer> <S-2-LeftMouse> :call ex#project#confirm_select('shift')<CR>
nnoremap <silent> <buffer> <C-k> :call ex#project#cursor_jump('\\C\\[F\\]', 'up')<CR>
nnoremap <silent> <buffer> <C-j> :call ex#project#cursor_jump('\\C\\[F\\]', 'down')<CR>
nnoremap <silent> <buffer> R :call ex#project#build_tree()<CR>
nnoremap <silent> <buffer> r :call ex#project#refresh_current_folder()<CR>
nnoremap <silent> <buffer> o :call ex#project#newfile()<CR>
nnoremap <silent> <buffer> O :call ex#project#newfolder()<CR>
" }}}1
