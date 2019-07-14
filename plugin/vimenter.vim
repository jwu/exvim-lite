function! s:find_exvim_folder()
  let exvim_dir_path = finddir(fnamemodify('.exvim', ':p'), '.;')
  if exvim_dir_path != ''
    let file = fnamemodify(exvim_dir_path.'/config.json', ':p')

    if filereadable(file)
      call ex#conf#load(file)
      return
    endif

    call ex#conf#new(file)
  endif
endfunction

augroup VIM_ENTER
  au!
  au VimEnter * call <SID>find_exvim_folder()
augroup END
