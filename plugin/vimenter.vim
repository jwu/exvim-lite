function! s:find_exvim_folder()
  let result = finddir(fnamemodify('.exvim', ':p'), '.;')
  if result != ""
    ex#warning(result)
  endif
endfunction

augroup VIM_ENTER
  au!
  au VimEnter * call <SID>find_exvim_folder()
augroup END
