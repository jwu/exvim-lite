" path separater depends by platform
let s:sep = '/'
if (has('win16') || has('win32') || has('win64'))
  let s:sep = '\'
endif

" ex#hint {{{1
" msg: string
function ex#hint(msg)
  silent echohl ModeMsg
  echon a:msg
  silent echohl None
endfunction

" ex#warning {{{1
" msg: string
function ex#warning(msg)
  silent echohl WarningMsg
  echomsg a:msg
  silent echohl None
endfunction

" ex#error {{{1
" msg: string
function ex#error(msg)
  silent echohl ErrorMsg
  echomsg 'Error(exVim): ' . a:msg
  silent echohl None
endfunction

" ex#debug {{{1
" msg: string
function ex#debug(msg)
  silent echohl Special
  echom 'Debug(exVim): ' . a:msg . ', ' . expand('<sfile>')
  silent echohl None
endfunction

" ex#short_message {{{1
" short the msg
function ex#short_message(msg)
  if len( a:msg ) <= &columns-13
    return a:msg
  endif

  let len = (&columns - 13 - 3) / 2
  return a:msg[:len] . "..." . a:msg[ (-len):]
endfunction

" ex#hl_clear_target {{{
function ex#hl_clear_target()
  2match none
endfunction

" ex#hl_target_line {{{
function ex#hl_target_line(linenr)
  " clear previous highlight result
  2match none

  " highlight the line pattern
  let pat = '/\%' . a:linenr . 'l.*/'
  silent exe '2match EX_TARGET_LINE ' . pat
endfunction

" ex#hl_clear_confirm {{{
function ex#hl_clear_confirm()
  3match none
endfunction

" ex#hl_confirm_line {{{
function ex#hl_confirm_line(linenr)
  " clear previous highlight result
  3match none

  " highlight the line pattern
  let pat = '/\%' . a:linenr . 'l.*/'
  silent exe '3match EX_CONFIRM_LINE ' . pat
endfunction

" ex#os_sep {{{
function ex#os_sep()
  return s:sep
endfunction
