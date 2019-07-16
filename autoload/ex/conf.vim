let s:old_titlestring = &titlestring
let s:old_tagrelative = &tagrelative
let s:old_tags = &tags

" ex#conf#reset {{{
function ex#conf#reset()
    let &titlestring = s:old_titlestring
    let &tagrelative = s:old_tagrelative
    let &tags = s:old_tags
endfunction

" ex#conf#new {{{
function ex#conf#new(file)
  let lines = [
        \ '{',
        \ '  "version": "'.g:exvim_ver.'",',
        \ '  "ignores": [',
        \ '    "**/.git",',
        \ '    "**/.svn",',
        \ '    "**/.exvim"',
        \ '  ],',
        \ '  "space": 2',
        \ '}'
        \ ]
  call writefile(lines, a:file)
  call ex#conf#load(a:file)
endfunction

" ex#conf#load {{{
function ex#conf#load(file)
  let lines = readfile(a:file)
  let conf = json_decode(join(lines))

  if conf.version != g:exvim_ver
    call ex#conf#new(a:file)
    return
  endif

  let g:exvim_dir = fnamemodify(a:file, ':p:h')
  let g:cwd = fnamemodify(a:file, ':p:h:h')

  " set parent working directory
  silent exec 'cd ' . fnameescape(g:cwd)
  let s:old_titlestring = &titlestring
  let &titlestring = "%{g:cwd}:\ %t\ (%{expand(\"%:p:.:h\")}/)"

  " set viewdir
  " NOTE: When the last path part of 'viewdir' does not exist, this directory is created
  let &viewdir = g:exvim_dir.'/view'

  " set tapstop
  let space = conf.space
  let &tabstop = space
  let &shiftwidth = space

  " set tagrelative
  let s:old_tagrelative = &tagrelative
  let &tagrelative = 0 " set notagrelative

  " set tags
  let s:old_tags = &tags
  let &tags = fnameescape(s:old_tags.','.g:exvim_dir.'/tags')

  " set wildignore
  let &wildignore = join(conf.ignores, ',')
endfunction
