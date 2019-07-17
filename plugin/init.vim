let g:exvim_ver = '1.0.6'
let g:exvim_dir = ''
let g:exvim_cwd = ''

function! s:barely_start_vim()
  if argc() == 0
    return 1
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
  if s:barely_start_vim()
    call ex#conf#show()
  endif
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
" }}}

" autocmd {{{
augroup VIM_ENTER
  au!
  au VimEnter * nested call <SID>find_exvim_folder()
augroup END
" }}}
