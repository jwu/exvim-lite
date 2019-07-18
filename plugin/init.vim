let g:exvim_ver = '1.0.6'
let g:exvim_dir = ''
let g:exvim_cwd = ''

function! s:barely_start_vim()
  if argc() == 0
    return 1
  endif

  " if this is a file
  if findfile(fnamemodify(argv(0), ':p')) !=# ''
    return 0
  endif

  if fnamemodify(argv(0), ':p:h') ==# fnamemodify(g:exvim_dir, ':p:h:h')
    return 1
  endif

  return 0
endfunction

function! s:find_exvim_folder() abort
  let path = finddir(fnamemodify('.exvim', ':p'), '.;')
  if path ==# ''
    return
  endif

  call ex#conf#load(path)
  " DISABLE:
  " if s:barely_start_vim()
  "   call ex#conf#show()
  " endif
endfunction

function! s:new_exvim_project(dir) abort
  let dir = fnamemodify(a:dir, ':p')
  if dir == ''
    ex#error("Can't find path: " . a:dir)
    return
  endif

  let exvim_dir_path = finddir(fnamemodify('.exvim', ':p'), dir)

  if exvim_dir_path == ''
    let exvim_dir_path = dir.'.exvim/'
    silent call mkdir(exvim_dir_path)
  endif

  call ex#conf#load(exvim_dir_path)
  call ex#conf#show()
endfunction

" commands {{{
" when EXVIM noargs, load {cwd}/.exvim/config.json
" when EXVIM foo/bar, load foo/bar/.exvim/config.json
command! -nargs=? -complete=dir EXVIM call <SID>new_exvim_project('<args>')

command! EXbn call ex#buffer#navigate('bn')
command! EXbp call ex#buffer#navigate('bp')
command! EXbalt call ex#buffer#to_alternate_edit_buf()
command! EXbd call ex#buffer#keep_window_bd()

command! EXsw call ex#window#switch_window()
command! EXgp call ex#window#goto_plugin_window()

command! EXplugins call ex#echo_registered_plugins()
" }}}

" autocmd {{{
augroup EXVIM
  au!
  au VimEnter * nested call <SID>find_exvim_folder()
  au VimEnter,WinLeave * call ex#window#record()
  au BufLeave * call ex#buffer#record()
augroup END
" }}}

" ex#register_plugin register plugins {{{
" register Vim builtin window
call ex#plugin#register('help', {'buftype': 'help'})
call ex#plugin#register('qf', {'buftype': 'quickfix'})
call ex#plugin#register('nerdtree', {'bufname': 'NERD_tree_\d\+', 'buftype': 'nofile'})
" call ex#plugin#register('minibufexpl', {'bufname': '-MiniBufExplorer-', 'buftype': 'nofile'})
" call ex#plugin#register('taglist', {'bufname': '__Tag_List__', 'buftype': 'nofile'})
" call ex#plugin#register('tagbar', {'bufname': '__TagBar__', 'buftype': 'nofile'})
" }}}
