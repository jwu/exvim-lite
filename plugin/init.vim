let g:exvim_ver = '1.0.6'
let g:exvim_dir = ''
let g:exvim_cwd = ''

" default configuration {{{1
if !exists('g:ex_search_winsize')
  let g:ex_search_winsize = 20
endif

if !exists('g:ex_search_winsize_zoom')
  let g:ex_search_winsize_zoom = 40
endif

" bottom or top
if !exists('g:ex_search_winpos')
  let g:ex_search_winpos = 'bottom'
endif

if !exists('g:ex_search_enable_sort')
  let g:ex_search_enable_sort = 1
endif

" will not sort the result if result lines more than x
if !exists('g:ex_search_sort_lines_threshold')
  let g:ex_search_sort_lines_threshold = 100
endif

if !exists('g:ex_search_enable_help')
  let g:ex_search_enable_help = 1
endif

if !exists('g:ex_search_globs')
  let g:ex_search_globs = ''
endif
"}}}

" internal functions {{{1
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
"}}}

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

command! -n=1 GS call ex#search#exec('<args>', '-s')
command! EXSearchCWord call ex#search#exec(expand('<cword>'), '-s')

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

" register plugins {{{
call ex#plugin#register('help', {'buftype': 'help'})
call ex#plugin#register('qf', {'buftype': 'quickfix'})
call ex#plugin#register('exsearch', {})
call ex#plugin#register('nerdtree', {'bufname': 'NERD_tree_\d\+', 'buftype': 'nofile'})
" call ex#plugin#register('minibufexpl', {'bufname': '-MiniBufExplorer-', 'buftype': 'nofile'})
" call ex#plugin#register('taglist', {'bufname': '__Tag_List__', 'buftype': 'nofile'})
" call ex#plugin#register('tagbar', {'bufname': '__TagBar__', 'buftype': 'nofile'})
" }}}

" highlight {{{
hi clear EX_CONFIRM_LINE
" hi default link EX_CONFIRM_LINE QuickFixLine
hi EX_CONFIRM_LINE gui=none guibg=#9f2f00 term=none cterm=none ctermbg=darkyellow

hi clear EX_TARGET_LINE
" hi default link EX_TARGET_LINE QuickFixLine
hi EX_TARGET_LINE gui=none guibg=#9f2f00 term=none cterm=none ctermbg=darkyellow
" }}}
