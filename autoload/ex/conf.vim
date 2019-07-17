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
function ex#conf#new_config(file)
  let lines = [
        \ '{',
        \ '  "version": "'.g:exvim_ver.'",',
        \ '  "space": 2,',
        \ '  "includes": [',
        \ '  ],',
        \ '  "ignores": [',
        \ '    "**/.DS_Store",',
        \ '    "**/.git",',
        \ '    "**/.svn",',
        \ '    "**/.vs",',
        \ '    "**/.vscode",',
        \ '    "**/.exvim",',
        \ '    "/[Ll]ibrary/",',
        \ '    "/ProjectSettings/",',
        \ '    "/[Ll]ogs/",',
        \ '    "/[Bb]uild/",',
        \ '    "/[Oo]bj/",',
        \ '    "/[Tt]emp/"',
        \ '  ]',
        \ '}'
        \ ]
  call writefile(lines, a:file)
endfunction

" ex#conf#load {{{
function ex#conf#load(dir)
  let file = fnamemodify(a:dir.'config.json', ':p')

  if !filereadable(file)
    call ex#conf#new_config(file)
  endif

  let lines = readfile(file)
  let conf = json_decode(join(lines))

  if conf.version != g:exvim_ver
    call ex#conf#new(file)
    return
  endif

  let g:exvim_dir = fnamemodify(a:dir, ':p')
  let g:exvim_cwd = fnamemodify(a:dir, ':p:h:h')

  " set parent working directory
  silent exec 'cd ' . fnameescape(g:exvim_cwd)
  let s:old_titlestring = &titlestring
  let &titlestring = "%{g:exvim_cwd}:\ %t\ (%{expand(\"%:p:.:h\")}/)"

  " set viewdir
  " NOTE: When the last path part of 'viewdir' does not exist, this directory is created
  let &viewdir = g:exvim_dir.'view'

  " set tapstop
  let space = conf.space
  let &tabstop = space
  let &softtabstop = space
  let &shiftwidth = space

  " set tagrelative
  let s:old_tagrelative = &tagrelative
  let &tagrelative = 0 " set notagrelative

  " set tags
  let s:old_tags = &tags
  let &tags = fnameescape(s:old_tags.','.g:exvim_dir.'tags')

  " set ack ignores
  if exists ( ':Ack' )
    let lines = []
    for ig in conf.ignores
      call add(lines, ig)
    endfor
    let ignore_file = fnamemodify(a:dir.'rgignores', ':p')
    call writefile(lines, ignore_file)
    let g:ackprg = 'rg --vimgrep --ignore-file ' . ignore_file
  endif

  " set ignores for ctrlp
  if g:loaded_ctrlp
    if executable('rg')
      let ignores = ''
      let includes = ''

      for ig in conf.ignores
        let ignores .= '-g !'.ig.' '
      endfor

      for ic in conf.includes
        let includes .= '-g '.ic.' '
      endfor

      " NOTE: includes should be first, then ignores will filter out include results
      let g:ctrlp_user_command = 'rg %s --no-ignore --hidden --files ' . includes . ' ' . ignores
    else
      " set wildignore
      " NOTE: wildignore don't support **/*
      let &wildignore = join(conf.ignores, ',')
      let g:ctrlp_custom_ignore = {
            \ 'dir':  '\v[\/]\.(git|hg|svn)$|target|node_modules|te?mp$|logs?$|public$|dist$',
            \ 'file': '\v\.(exe|so|dll|ttf|png|gif|jpe?g|bpm)$|\-rplugin\~',
            \ 'link': 'some_bad_symbolic_links',
            \ }
    endif
  endif

  " set ignores for nerdtree
  if g:loaded_nerd_tree
    let g:NERDTreeIgnore = []
    for ig in conf.ignores
      if ig =~# '^\*\..*'
        call add(g:NERDTreeIgnore, '\'.strpart(ig,1))
      endif
    endfor
  endif
endfunction

" ex#conf#show {{{
function ex#conf#show()
  let file = fnamemodify(g:exvim_dir.'config.json', ':p')
  if filereadable(file)
    exe ' silent e ' . escape(file, ' ')

    " do not show it in buffer list
    setlocal bufhidden=hide
    setlocal noswapfile
    setlocal nobuflisted
    setlocal nowrap

    augroup EXVIM_BUFFER
      au! BufWritePost <buffer> call ex#conf#load(g:exvim_dir)
    augroup END
  endif
endfunction
