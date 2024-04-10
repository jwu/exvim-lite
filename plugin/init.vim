let g:exvim_ver = '1.1.0'
let g:exvim_dir = ''
let g:exvim_cwd = ''

" ex_search default configuration {{{1
if !exists('g:ex_search_winsize')
  let g:ex_search_winsize = 15
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

if !exists('g:ex_search_globs')
  let g:ex_search_globs = ''
endif
"}}}

" ex_project default configuration {{{1
if !exists('g:ex_project_file')
  let g:ex_project_file = "./.exvim/files.exproject"
endif

if !exists('g:ex_project_winsize')
  let g:ex_project_winsize = 30
endif

if !exists('g:ex_project_winsize_zoom')
  let g:ex_project_winsize_zoom = 60
endif

" left or right
if !exists('g:ex_project_winpos')
  let g:ex_project_winpos = 'left'
endif

if !exists('g:ex_project_globs')
  let g:ex_project_globs = ''
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

function! s:find_exvim_folder()
  " find .exvim/ upward recursively
  let path = finddir('.exvim', '.;')
  if path ==# ''
    return
  endif

  " NOTE: cwd will changed when ex#conf#load invoked
  let target = fnamemodify(argv(0), ':p')

  " make sure we have '/' suffix for dir
  let path .= '/'
  call ex#conf#load(path)

  " if we have file to edit
  if findfile(target) ==# ''
    call ex#conf#show()
  endif

  silent exec 'EXProject'

  if findfile(target) !=# '' || finddir(target) !=# ''
    silent exec 'EXProjectFind ' . target
  endif
endfunction

function! s:new_exvim_project(dir)
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
command! EXgc call ex#window#close_last_edit_plugin_window()

command! EXplugins call ex#echo_registered_plugins()

" ex-search
command! -n=1 GS call ex#search#exec('<args>', '-s')
command! EXSearchCWord call ex#search#exec(expand('<cword>'), '-s')

" ex-project
command! -n=? -complete=file EXProject call ex#project#open('<args>')
command! -n=? -complete=file EXProjectFind call ex#project#find('<args>')
" }}}

" autocmd {{{
augroup EXVIM
  au!
  au VimEnter * nested call <SID>find_exvim_folder()
  au VimEnter,WinLeave * call ex#window#record()
  au BufLeave * call ex#buffer#record()
  au WinClosed * call ex#window#goto_edit_window()
augroup END
" }}}

" register plugins {{{
call ex#plugin#register('help', {'buftype': 'help'})
call ex#plugin#register('qf', {'buftype': 'quickfix'})
call ex#plugin#register('exsearch', {})
call ex#plugin#register('exproject', {})
call ex#plugin#register('nerdtree', {'bufname': 'NERD_tree_\d\+', 'buftype': 'nofile'})
call ex#plugin#register('NvimTree', {})
" }}}

" highlight {{{
" #702963, #4b382a
hi clear EX_CONFIRM_LINE
hi EX_CONFIRM_LINE gui=none guibg=#702963 term=none cterm=none ctermbg=darkyellow

hi clear EX_TARGET_LINE
hi EX_TARGET_LINE gui=none guibg=#702963 term=none cterm=none ctermbg=darkyellow

hi clear EX_TRANSPARENT
hi EX_TRANSPARENT gui=none guifg=background term=none cterm=none ctermfg=darkgray
" }}}
