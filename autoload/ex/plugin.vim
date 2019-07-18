" ex#plugin#register {{{1

" NOTE: if the filetype is empty, exvim will use '__EMPTY__' rules to check your buffer
let s:registered_plugins = {}

" debug print of registered plugins
function ex#plugin#echo_registered()
  silent echohl Statement
  echo 'List of registered plugins:'
  silent echohl None

  for [k,v] in items(s:registered_plugins)
    if empty(v)
      echo k . ': {}'
    else
      for i in v
        echo k . ': ' . string(i)
      endfor
    endif
  endfor
endfunction

" filetype: the filetype you wish to register as plugin, can be ''
" options: buffer options you wish to check
" special options: bufname, winpos
function ex#plugin#register(filetype, options)
  let filetype = a:filetype
  if filetype == ''
    let filetype = '__EMPTY__'
  endif

  " get rules by filetype, if not found add new rules
  let rules = []
  if !has_key( s:registered_plugins, filetype )
    let s:registered_plugins[filetype] = rules
  else
    let rules = s:registered_plugins[filetype]
  endif

  " check if we have options
  if !empty(a:options)
    silent call add ( rules, a:options )
  endif
endfunction

" ex#plugin#is_registered {{{1
function ex#plugin#is_registered(bufnr)
  " if the buf didn't exists, don't do anything else
  if !bufexists(a:bufnr)
    return 0
  endif

  let bufname = bufname(a:bufnr)
  let filetype = getbufvar( a:bufnr, '&filetype' )

  " if this is not empty filetype, use regular rules for buffer checking
  if filetype == ''
    let filetype = "__EMPTY__"
  endif

  " get rules directly from registered dict, if rules not found,
  " simply return flase because we didn't register the filetype
  if !has_key( s:registered_plugins, filetype )
    return 0
  endif

  " if rules is empty, which means it just need to check the filetype
  let rules = s:registered_plugins[filetype]
  if empty(rules)
    return 1
  endif

  " check each rule dict to make sure this buffer meet our request
  for ruledict in rules
    let failed = 0

    for key in keys(ruledict)
      " NOTE: this is because the value here can be list or string, if
      " we don't unlet it, it will lead to E706
      if exists('l:value')
        unlet value
      endif
      let value = ruledict[key]

      " check bufname
      if key ==# 'bufname'
        if match( bufname, value ) == -1
          let failed = 1
          break
        endif

        continue
      endif

      " check other option
      let bufoption = getbufvar(a:bufnr, '&'.key)
      if bufoption !=# value
        let failed = 1
        break
      endif
    endfor

    " congratuation, all rules passed!
    if failed == 0
      return 1
    endif
  endfor

  return 0
endfunction
