let g:cwd = ''
let g:exvim_dir = ''
let g:exvim_ver = '1.0.1'

function! s:find_exvim_folder() abort
  let exvim_dir_path = finddir(fnamemodify('.exvim', ':p'), '.;')
  if exvim_dir_path != ''
    let file = fnamemodify(exvim_dir_path.'config.json', ':p')

    if filereadable(file)
      call ex#conf#load(file)
      return
    endif

    call ex#conf#new(file)
  endif
endfunction

function! s:new_exvim_project(dir) abort
  let dir = fnamemodify(a:dir, ':p')
  if dir == ''
    ex#error("Can't find path: " . a:dir)
    return
  endif

  let exvim_dir_path = finddir('.exvim', dir)

  if exvim_dir_path == ''
    let exvim_dir_path = dir.'.exvim'
    silent call mkdir(exvim_dir_path)
  endif

  let file = fnamemodify(exvim_dir_path.'/config.json', ':p')
  if filereadable(file)
    call ex#conf#load(file)
    exe ' silent e ' . escape(file, ' ')
    return
  endif

  call ex#conf#new(file)
  exe ' silent e ' . escape(file, ' ')
endfunction

" commands {{{
" when EXVIM noargs, load {cwd}/.exvim/config.json
" when EXVIM foo/bar, load foo/bar/.exvim/config.json
command! -nargs=? -complete=dir EXVIM call <SID>new_exvim_project('<args>')
" }}}

" autocmd {{{
augroup VIM_ENTER
  au!
  au VimEnter * call <SID>find_exvim_folder()
augroup END
" }}}
