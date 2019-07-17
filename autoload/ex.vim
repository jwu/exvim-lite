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
function ex#short_message( msg )
  if len( a:msg ) <= &columns-13
    return a:msg
  endif

  let len = (&columns - 13 - 3) / 2
  return a:msg[:len] . "..." . a:msg[ (-len):]
endfunction
