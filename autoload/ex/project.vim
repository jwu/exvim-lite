" variables {{{1
let s:cur_project_file = ''

let s:ignore_patterns = ''
let s:include_patterns = ''

let s:zoom_in = 0

let s:help_open = 0
let s:help_default = [
      \ '" Press <F1> for help',
      \ '',
      \ '" <F1>: Toggle Help',
      \ '" <Space>: Zoom in/out project window',
      \ '" <Enter>: Open file or fold in/out folder',
      \ '" <2-LeftMouse>: Open file or fold in/out folder',
      \ '" <Shift-Enter>: Open file in split window or open folder in os file browser',
      \ '" <Ctrl-k>: Move cursor up to the nearest folder',
      \ '" <Ctrl-j>: Move cursor down to the nearest folder',
      \ '" <R>: Refresh the project',
      \ '" <r>: Refresh current folder',
      \ '" <O>: Create new folder',
      \ '" <o>: Create new file',
      \ ]
let s:help_short = [
      \ '" Press <F1> for help',
      \ '',
      \ ]
let s:help_text = s:help_short

" internal functions {{{1

" s:os_is {{{2
function s:os_is(name)
  if a:name ==# 'osx'
    return has('macunix')
  elseif a:name ==# 'windows'
    return  (has('win16') || has('win32') || has('win64'))
  elseif a:name ==# 'linux'
    return has('unix') && !has('macunix') && !has('win32unix')
  else
    call ex#warning( 'Invalide name ' . a:name . ", Please use 'osx', 'windows' or 'linux'" )
  endif

  return 0
endfunction

" s:os_open {{{2
function s:os_open(path)
  let path = shellescape(a:path)

  if s:os_is('osx')
    silent exec '!open ' . path
    call ex#hint('open ' . path)
  elseif s:os_is('windows')
    let path = substitute(path, '\/', '\\', 'g')
    silent exec '!explorer ' . path
    call ex#hint('explorer ' . path)
  else
    call ex#warning( 'File borwser not support in Linux' )
  endif
endfunction

" s:mk_pattern
function s:mk_pattern(list)
  let pattern = '\m'
  for item in a:list
    if item == ''
      continue
    endif

    " replace foo.bar to foo\.bar
    " replace $foobar to \$foobar
    " replace ~foobar to \~foobar
    let item = escape(item, '.~$')

    " replace foo/**/* to foo/.*
    let item = substitute(item, '\*\*\/\*', '.*', 'g')

    " replace foo/** to foo/.*
    let item = substitute(item, '\*\*', '.*', 'g')

    " replace foo/** to foo/.*
    let item = substitute(item, '\([^.]\)\*', '\1[^/]*', 'g')

    " replace *\.foo to [^/]*\.foo$
    let item = substitute(item, '^\*\\\.\(\S\+\)$', '[^/]*\.\1$', 'g')

    " append \|
    let pattern = pattern . item . '\|'
  endfor
  let pattern = strpart(pattern, 0, strlen(pattern)-2)

  if s:os_is('windows')
    let pattern = substitute(pattern, '\/', '\\\\', 'g')
  endif

  return pattern
endfunction

" s:search_for_pattern {{{2
function s:search_for_pattern( linenr, pattern )
  for linenr in range(a:linenr , 1 , -1)
    if match(getline(linenr) , a:pattern) != -1
      return linenr
    endif
  endfor
  return 0
endfunction

" s:getname {{{2
function s:getname(linenr)
  let line = getline(a:linenr)
  " let line = substitute(line,'.\{-}\[.\{-}\]\(.\{-}\)','\1','')
  let line = substitute(line,'.\{-}-\(\[F\]\)\{0,1}\(.\{-}\)','\2','')
  let idx_end_1 = stridx(line,' {')
  let idx_end_2 = stridx(line,' }')
  if idx_end_1 != -1
    let line = strpart(line,0,idx_end_1)
  elseif idx_end_2 != -1
    let line = strpart(line,0,idx_end_2)
  endif
  return line
endfunction

" s:getpath {{{2
" Desc: Get the full path of the line, by YJR
function s:getpath(linenr)
  let foldlevel = s:getfoldlevel(a:linenr)
  let fullpath = ''

  " recursively make full path
  if match(getline(a:linenr), '[^^]-\C\[F\]') != -1
    let fullpath = s:getname(a:linenr)
  endif

  let level_pattern = repeat('.',foldlevel-1)
  let searchpos = a:linenr
  while foldlevel > 1 " don't parse level:0
    let foldlevel -= 1
    let level_pattern = repeat('.',foldlevel*2)
    let fold_pattern = '^'.level_pattern.'-\C\[F\]'
    let searchpos = s:search_for_pattern(searchpos , fold_pattern)
    if searchpos
      let fullpath = s:getname(searchpos).'/'.fullpath
    else
      call ex#warning('Fold not found')
      break
    endif
  endwhile

  return fullpath
endfunction

" s:getfoldlevel {{{2
function s:getfoldlevel(linenr)
  let curline = getline(a:linenr)
  let curline = strpart(curline,0,strridx(curline,'|')+1)
  let str_len = strlen(curline)
  return str_len/2
endfunction

" s:set_level_list {{{2
function s:set_level_list( linenr )
  " clean the list
  let s:level_list = []

  let cur_line = getline(a:linenr+1)
  let idx = strridx(cur_line, '|') -2
  let cur_line = strpart(cur_line, 1, idx)

  let len = strlen(cur_line)
  let idx = 0
  while idx <= len
    if cur_line[idx] == '|'
      silent call add( s:level_list, {'is_last':0,'dirname':''} )
    else
      silent call add( s:level_list, {'is_last':1,'dirname':''} )
    endif
    let idx += 2
  endwhile
endfunction

" s:on_close {{{2
function s:on_close()
  let s:zoom_in = 0
  let s:help_open = 0

  " go back to edit buffer
  call ex#window#goto_edit_window()
endfunction

" s:on_save {{{2
function s:on_save()
  if s:help_open
    let cursor_line = line('.')
    let cursor_col = col('.')
    let cursor_line = cursor_line - (len(s:help_text) - len(s:help_short))

    call ex#project#toggle_help()

    silent call cursor(cursor_line,cursor_col)
    silent normal! zz
  endif
endfunction

" s:build_tree {{{2
function s:build_tree(path, ignore_patterns, include_patterns)
  " show progress
  " echon ex#short_message( 'processing: ' . fnamemodify(a:path, ':p:.') ) . "\r"

  " get dirname
  " let dirname = strpart( a:path, strridx(a:path,'\')+1 )
  let dirname = fnamemodify(a:path, ':t')
  let is_dir = isdirectory(a:path)

  " if directory
  if is_dir == 1
    " split the first level to results
    let results = split(globpath(a:path, '*'), '\n') " NOTE, globpath('.','.*') will show hidden folder
    let inc_list = []
    silent call sort(results)

    " sort and filter the list as we want (file|dir )
    let list_idx = 0
    let list_last = len(results)-1
    let list_count = 0
    while list_count <= list_last
      let result = results[list_idx]

      " remove ignore results
      if match(result, a:ignore_patterns) != -1
        silent call remove(results, list_idx)

        let list_count += 1
        continue
      endif

      " if this is a file
      if isdirectory(result) == 0
        " check if the file is in include_patterns
        " NOTE: don't check include_patterns for directory
        if match(result, a:include_patterns) == -1
          silent call remove(results, list_idx)

          let list_count += 1
          continue
        endif

        " move the file to the end of the list
        let file = remove(results, list_idx)
        silent call add(results, file)

        let list_count += 1
        continue
      endif

      let list_idx += 1
      let list_count += 1
    endwhile

    silent call add(s:level_list, {'is_last': 0, 'dirname': dirname})

    " recuseve browse list
    let list_last = len(results)-1
    let list_idx = list_last
    let s:level_list[len(s:level_list)-1].is_last = 1
    while list_idx >= 0
      if list_idx != list_last
        let s:level_list[len(s:level_list)-1].is_last = 0
      endif

      " if the folder is empty or the folder/file is not added by filter
      if s:build_tree(
            \ results[list_idx],
            \ a:ignore_patterns,
            \ a:include_patterns
            \ ) == 1
        silent call remove(results, list_idx)
        let list_last = len(results)-1
      endif

      let list_idx -= 1
    endwhile

    silent call remove(s:level_list, len(s:level_list)-1)

    if len(results) == 0
      return 1
    endif
  endif

  " write space
  let space = repeat(' |', len(s:level_list)) . '-'

  " get end_fold
  let end_fold = ''
  let rev_list = reverse(copy(s:level_list))
  for level in rev_list
    if level.is_last == 0
      break
    endif

    let end_fold = end_fold . ' }'
  endfor

  " judge if it is a dir
  if is_dir == 0
    " if file_end enter a new line for it
    if end_fold != ''
      let end_space = strpart(space, 0, strridx(space, '-') - 1)
      let end_space = strpart(end_space, 0, strridx(end_space, '|') + 1)
      silent put! = end_space " . end_fold
    endif

    " put it
    " let file_type = strpart(dirname, strridx(dirname,'.')+1, 1)
    let file_type = strpart(fnamemodify(dirname, ":e"), 0, 1)
    " silent put! = space.'['.file_type.']'.dirname . end_fold
    silent put! = space . dirname . end_fold
    return 0
  else
    "silent put = strpart(space, 0, strridx(space,'\|-')+1)
    if len(results) == 0 " if it is a empty directory
      if end_fold == ''
        " if dir_end enter a new line for it
        let end_space = strpart(space, 0, strridx(space, '-'))
      else
        " if dir_end enter a new line for it
        let end_space = strpart(space, 0, strridx(space, '-')-1)
        let end_space = strpart(end_space, 0, strridx(end_space,'|')+1)
      endif
      let end_fold = end_fold . ' }'
      silent put! = end_space
      silent put! = space . '[F]' . dirname . ' {' . end_fold
    else
      silent put! = space . '[F]' . dirname . ' {'
    endif
  endif

  return 0
endfunction
" }}}1

" functions {{{1

" ex#project#toggle_help {{{2
function ex#project#toggle_help()
  let s:help_open = !s:help_open
  silent exec '1,' . len(s:help_text) . 'd _'

  if s:help_open
    let s:help_text = s:help_default
  else
    let s:help_text = s:help_short
  endif

  silent call append ( 0, s:help_text )
  silent keepjumps normal! gg
  call ex#hl_clear_confirm()
endfunction

" ex#project#open {{{2
function ex#project#open(filename)
  " if the filename is empty, use default project file
  let filename = a:filename
  if filename == ""
    let filename = g:ex_project_file
  endif

  " if we open a different project, close the old one first.
  if filename !=# s:cur_project_file
    if s:cur_project_file != ""
      let winnr = bufwinnr(s:cur_project_file)
      if winnr != -1
        call ex#window#close(winnr)
      endif
    endif

    " reset project filename and title.
    let s:cur_project_file = a:filename
  endif

  " open and goto the window
  call ex#project#open_window()
endfunction

" ex#project#open_window {{{2

function ex#project#init_buffer()
  " NOTE: ex-project window open can happen during VimEnter. According to
  " Vim's documentation, event such as BufEnter, WinEnter will not be triggered
  " during VimEnter.
  " When I open exproject window and read the file through vimentry scripts,
  " the events define in exproject/ftdetect/exproject.vim will not execute.
  " I guess this is because when you are in BufEnter event( the .vimentry
  " enters ), and open the other buffers, the Vim will not trigger other
  " buffers' event
  " This is why I set the filetype manually here.
  set filetype=exproject
  augroup EXVIM_PROJECT
    au!
    au BufWinLeave <buffer> call <SID>on_close()
    au BufWritePre <buffer> call <SID>on_save()
  augroup END

  if line('$') <= 1
    silent call append ( 0, s:help_text )
    silent exec '$d'
  endif
endfunction

function ex#project#open_window()
  let winnr = winnr()
  call ex#window#goto_edit_window()

  if s:cur_project_file == ""
    let s:cur_project_file = g:ex_project_file
  endif

  let winnr = bufwinnr(s:cur_project_file)
  if winnr == -1
    call ex#window#open(
          \ s:cur_project_file,
          \ g:ex_project_winsize,
          \ g:ex_project_winpos,
          \ 0,
          \ 1,
          \ function('ex#project#init_buffer')
          \ )
  else
    exe winnr . 'wincmd w'
  endif
endfunction

" ex#project#toggle_window {{{2
function ex#project#toggle_window()
  let result = ex#project#close_window()
  if result == 0
    call ex#project#open_window()
  endif
endfunction

" ex#project#close_window {{{2
function ex#project#close_window()
  if s:cur_project_file != ""
    let winnr = bufwinnr(s:cur_project_file)
    if winnr != -1
      call ex#window#close(winnr)
      return 1
    endif
  endif
  return 0
endfunction

" ex#project#toggle_zoom {{{2
function ex#project#toggle_zoom()
  if s:cur_project_file != ""
    let winnr = bufwinnr(s:cur_project_file)
    if winnr != -1
      if s:zoom_in == 0
        let s:zoom_in = 1
        call ex#window#resize( winnr, g:ex_project_winpos, g:ex_project_winsize_zoom )
      else
        let s:zoom_in = 0
        call ex#window#resize( winnr, g:ex_project_winpos, g:ex_project_winsize )
      endif
    endif
  endif
endfunction

" ex#project#foldtext {{{2
" This functions used in ftplugin/exproject.vim for 'setlocal foldtext='
function ex#project#foldtext()
  let line = getline(v:foldstart)
  let line = substitute(line,'\[F\]\(.\{-}\) {.*','\[+\]\1 ','')
  return line
endfunction

" ex#project#confirm_select {{{2
" modifier: '' or 'shift'
function ex#project#confirm_select(modifier)
  " check if the line is valid file line
  let curline = getline('.')
  if match(curline, '-\(\C\[.*\]\)\{0,1}') == -1
    call ex#warning('Please select a folder/file')
    return
  endif

  let editcmd = 'e'
  if a:modifier == 'shift'
    let editcmd = 'bel sp'
  endif

  " initial variable
  let cursor_line = line('.')
  let cursor_col = col('.')

  " if this is a fold, do fold operation or open the path by terminal
  if foldclosed('.') != -1 || match(curline, '\C\[F\]') != -1
    if a:modifier == 'shift'
      call s:os_open(s:getpath(cursor_line))
    else
      normal! za
    endif
    return
  endif

  let fullpath = s:getpath(cursor_line) . s:getname(cursor_line)

  silent call cursor(cursor_line,cursor_col)

  " simplify the file name
  let fullpath = fnamemodify( fullpath, ':p' )
  let fullpath = fnameescape(fullpath)

  " switch filetype
  let filetype = fnamemodify( fullpath, ':e' )
  if filetype == 'err'
    " TODO:
    " call ex#hint('load quick fix list: ' . fullpath)
    " call exUtility#GotoPluginBuffer()
    " silent exec 'QF '.fullpath
    " " NOTE: when open error by QF, we don't want to exec exUtility#OperateWindow below ( we want keep stay in the exQF plugin ), so return directly
    return
  elseif filetype == 'exe'
    " TODO:
    " call ex#hint('debug ' . fullpath)
    " call exUtility#GotoEditBuffer()
    " call exUtility#Debug( fullpath )
    return
  else " default
    " put the edit file
    call ex#hint(fnamemodify(fullpath, ':p:.'))

    " zoom out project before we goto edit window
    if s:zoom_in == 1
      call ex#project#toggle_zoom()
    endif

    " goto edit window
    call ex#window#goto_edit_window()

    " TODO: we need to findfile, finddir, if both not exists, warning user.

    " do not open again if the current buffer is the file to be opened
    if fnamemodify(expand('%'),':p') != fnamemodify(fullpath,':p')
      silent exec editcmd.' '.fullpath
    endif
  endif
endfunction

" ex#project#build_tree {{{2
function ex#project#build_tree()
  let s:level_list = [] " init level list

  " get entry dir
  let cwd = getcwd()
  if exists('g:exvim_cwd')
    let cwd = g:exvim_cwd
  endif

  echon 'Creating ex_project: ' . cwd . "\r"
  silent exec '1,$d _'

  " start tree building
  call s:build_tree(
        \ cwd,
        \ s:ignore_patterns,
        \ s:include_patterns
        \ )

  silent keepjumps normal! gg

  " add online help
  silent call append ( 0, s:help_text )

  " save the build
  silent exec 'w!'
  echon 'ex_project: ' . cwd . ' created!' . "\r"
endfunction

" ex#project#find {{{2
function ex#project#find(path)
  " first jump to edit window
  call ex#window#goto_edit_window()

  " if path is empty, find current edit buffer
  let path = a:path
  if path ==# ''
    let path = bufname('%')
  endif

  " strip last separator
  if path[strlen(path)-1] ==# ex#os_sep()
    let path = strpart(path, 0, strlen(path)-1)
  endif

  let filename = fnamemodify(path, ':t')
  let filepath = fnamemodify(path, ':p')
  let is_dir = isdirectory(filepath)

  " go to the project window
  call ex#project#open_window()

  " store position if we don't find, restore to the position
  let cursor_line = line('.')
  let cursor_col = col('.')

  " now go to the top start search
  silent normal gg

  " process search
  let found = 0
  while !found
    if search(filename, 'W') > 0
      let linenr = line('.')
      let searchfilename = s:getpath(linenr)

      if !is_dir
        let searchfilename = searchfilename . s:getname(linenr)
      endif

      if fnamemodify(searchfilename , ':p') == filepath
        silent call cursor(linenr, 0)

        " unfold the line if it's folded
        silent normal! zv

        " if find, set the text line in the middel of the window
        silent normal! zz

        let found = 1
        echon 'Locate file: ' . path . "\r"
        break
      endif

    " if file not found, warning and back to edit window regardless a:focus
    else
      silent call cursor(cursor_line, cursor_col)
      call ex#warning('File not found: ' . fnamemodify(filepath, ':p:.') )
      call ex#window#goto_edit_window()

      return
    endif
  endwhile
endfunction

" ex#project#refresh_current_folder {{{2
function ex#project#refresh_current_folder()
  let s:level_list = [] " init level list

  " if the line is neither a file/folder line nor a root folder line, return
  let file_line = getline('.')
  if match(file_line, '\( |\)\+-\{0,1}.*') == -1 && match(file_line, '-\C\[F\]') == -1
    call ex#warning( "Please select a file/folder for refresh" )
    return
  endif

  " if fold, open it else if not a file return
  if foldclosed('.') != -1
    normal! zr
  endif

  " initial variable
  let fold_level = s:getfoldlevel(line('.'))
  let fold_level -= 1
  let level_pattern = repeat('.',fold_level*2)
  let full_path_name = ''
  let fold_pattern = '^'.level_pattern.'-\C\[F\]'

  " get first fold name
  if match(file_line, '\C\[F\]') == -1
    if search(fold_pattern,'b')
      let full_path_name = s:getname(line('.'))
    else
      call ex#warning('The project may broke, fold pattern not found: ' . fold_pattern)
      return
    endif
  else
    let full_path_name = s:getname(line('.'))
    let fold_level += 1
  endif
  let dirname = full_path_name

  " fold_level 0 will not set path name
  if fold_level == 0
    let full_path_name = ''
  endif

  " save the position
  let cursor_line = line('.')
  let cursor_col = col('.')

  " recursively make full path
  let is_root = 0
  if fold_level == 0
    let is_root = 1
  else
    while fold_level > 1
      let fold_level -= 1
      let level_pattern = repeat('.',fold_level*2)
      let fold_pattern = '^'.level_pattern.'-\C\[F\]'
      if search(fold_pattern,'b')
        let full_path_name = s:getname(line('.')).'/'.full_path_name
      else
        call ex#warning('The project may broke, fold pattern not found: ' . fold_pattern)
        break
      endif
    endwhile
  endif
  silent call cursor(cursor_line,cursor_col)

  " simplify the file name
  let full_path_name = fnamemodify( full_path_name, ':p' )
  " do not escape, or the directory with white-space can't be found
  "let full_path_name = fnameescape(simplify(full_path_name))
  let full_path_name = strpart( full_path_name, 0, strlen(full_path_name)-1 )
  echon "ex-project: Refresh folder: " . full_path_name . "\r"

  " set level list if not the root dir
  if is_root == 0
    call s:set_level_list(line('.'))
  endif
  " delete the whole fold
  silent exec "normal! zc"
  silent exec 'normal! "_2dd'

  " start broswing
  call s:build_tree(
        \ full_path_name,
        \ s:ignore_patterns,
        \ s:include_patterns
        \ )

  " at the end, we need to rename the folder as simple one rename the folder
  let cur_line = getline('.')

  " if this is a empty directory, return
  let pattern = '\C\[F\].*\<' . dirname . '\> {'
  if match(cur_line, pattern) == -1
    call ex#warning ('The folder is empty')
    return
  endif

  let idx_start = stridx(cur_line, ']')
  let start_part = strpart(cur_line,0,idx_start+1)

  let idx_end = stridx(cur_line, ' {')
  let end_part = strpart(cur_line,idx_end)

  silent call setline('.', start_part . dirname . end_part)

  " save the changes
  silent exec 'w!'
  echon "ex-project: Refresh folder: " . full_path_name . " done!\r"
endfunction

" ex#project#set_filters {{{2
function ex#project#set_filters(ignores, includes)
  let s:ignore_patterns = s:mk_pattern(a:ignores)
  let s:include_patterns = s:mk_pattern(a:includes)
endfunction

" ex#project#newfile {{{2
function ex#project#newfile()
  " check if the line is valid file line
  let cur_line = getline('.')
  if match(cur_line, '\( |\)\+-.*') == -1
    call ex#warning ("Can't create new file here. Please move your cursor to a file or a folder.")
    return
  endif

  let reg_t = @t
  if foldclosed('.') != -1
    silent exec 'normal! j"tyy"t2p$a-'
    return
  endif

  " if this is directory
  if match(cur_line, '\C\[F\]') != -1
    let idx = stridx(cur_line, '}')
    if idx == -1
      silent exec 'normal! j"tyy"tP'
      silent call search('|-', 'c')
      silent exec 'normal! c$|-'
      silent exec 'startinsert!'
    else
      let surfix = strpart(cur_line,idx-1)
      silent call setline('.',strpart(cur_line,0,idx-1))
      let file_line = strpart(cur_line, 0, stridx(cur_line,'-')) . " |-" . surfix
      put = file_line
      silent call search(' }', 'c')
      silent exec 'startinsert'
    endif
    " if this is file
  else
    let idx = stridx(cur_line, '}')
    if idx == -1
      silent exec 'normal! "tyyj"tP'
      silent call search('|-','c')
      silent exec 'normal! c$|-'
      silent exec 'startinsert!'
    else
      let surfix = strpart(cur_line,idx-1)
      silent call setline('.',strpart(cur_line,0,idx-1))
      let file_line = strpart(cur_line, 0, stridx(cur_line,'-')) . "-" . surfix
      put = file_line
      silent call search(' }','c')
      silent exec 'startinsert'
    endif
  endif
  let @t = reg_t
endfunction

" ex#project#newfolder {{{2
function ex#project#newfolder()
  " check if the line is valid folder line
  let cur_line = getline('.')
  if match(cur_line, '\C\[F\]') == -1
    call ex#warning ("Can't create new folder here, Please move your cursor to a parent folder.")
    return
  endif

  " let foldername = inputdialog( 'Folder Name: ', '' )
  silent echohl Question
  let foldername = input( 'Folder Name: ', '' )
  silent echohl none

  if foldername == ''
    call ex#warning ("Can't create empty folder.")
    return
  else
    let path = s:getpath(line('.'))
    if finddir( foldername, path ) != ''
      call ex#warning (" The folder " . foldername . " already exists!" )
      return
    endif

    if path == ''
      let path = '.'
    endif
    call mkdir( path . '/' . foldername )
    call ex#hint ( " created!" )
  endif

  let reg_t = @t
  if foldclosed('.') != -1
    silent exec 'normal! j"tyy"t2p$a-[F]' . foldername . ' { }'
    return
  endif

  let idx = stridx(cur_line, '}')
  if idx == -1
    let file_line = cur_line
    put = file_line
    silent call search('-\[F\]','c')
    silent exec 'normal! c$ |-[F]' . foldername . ' { }'
  else
    let surfix = strpart(cur_line,idx-1)
    silent call setline('.',strpart(cur_line,0,idx-1))
    let file_line = strpart(cur_line, 0, stridx(cur_line,'-'))
          \ . ' |-[F]'
          \ . foldername
          \ . ' { }'
          \ . surfix
    put = file_line
  endif

  let @t = reg_t
endfunction

" ex#project#cursor_jump {{{2
function ex#project#cursor_jump ( search_pattern, search_direction )
  let save_cursor = getpos(".")

  " get search flags, also move cursors
  let search_flags = ''
  if a:search_direction == 'up'
    let search_flags  = 'bW'
    silent exec 'normal ^'
  else
    let search_flags  = 'W'
    silent exec 'normal $'
  endif

  " jump to error,warning pattern
  let jump_line = search(a:search_pattern, search_flags )
  if jump_line == 0
    silent call setpos(".", save_cursor)
  endif
endfunction

" }}}1
