let s:old_titlestring = &titlestring
let s:old_tagrelative = &tagrelative
let s:old_tags = &tags

" ex#conf#reset {{{
function ex#conf#reset()
    let &titlestring = s:old_titlestring
    let &tagrelative = s:old_tagrelative
    let &tags = s:old_tags
endfunction

" ex#conf#new_config {{{
function ex#conf#new_config(file)
  let lines = [
        \ '{',
        \ '  "version": "'.g:exvim_ver.'",',
        \ '  "space": 2,',
        \ '  "includes": [',
        \ '    "*.asm",',
        \ '    "*.bat",',
        \ '    "*.sh",',
        \ '    "*.bash",',
        \ '    "*.c",',
        \ '    "*.cc",',
        \ '    "*.cp",',
        \ '    "*.cpp",',
        \ '    "*.cs",',
        \ '    "*.cxx",',
        \ '    "*.h",',
        \ '    "*.hh",',
        \ '    "*.hpp",',
        \ '    "*.hxx",',
        \ '    "*.inl",',
        \ '    "*.go",',
        \ '    "*.js",',
        \ '    "*.ts",',
        \ '    "*.css",',
        \ '    "*.html",',
        \ '    "*.json",',
        \ '    "*.xml",',
        \ '    "*.yaml",',
        \ '    "*.lua",',
        \ '    "*.md",',
        \ '    "*.markdown",',
        \ '    "*.m",',
        \ '    "*.makefile",',
        \ '    "*.mk",',
        \ '    "*.mak",',
        \ '    "*.pl",',
        \ '    "*.perl",',
        \ '    "*.py",',
        \ '    "*.rb",',
        \ '    "*.ruby",',
        \ '    "*.hlsl",',
        \ '    "*.glsl",',
        \ '    "*.vsh",',
        \ '    "*.psh",',
        \ '    "*.fx",',
        \ '    "*.fxh",',
        \ '    "*.cg",',
        \ '    "*.cginc",',
        \ '    "*.shd",',
        \ '    "*.shader",',
        \ '    "*.vim"',
        \ '  ],',
        \ '  "ignores": [',
        \ '    "**/.DS_Store",',
        \ '    "**/.git",',
        \ '    "**/.svn",',
        \ '    "**/.vs",',
        \ '    "**/.vscode",',
        \ '    "**/.exvim",',
        \ '    "**/*.meta",',
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
    call ex#conf#new_config(file)
    return
  endif

  " check if rg installed
  if !executable('rg')
    call ex#warning('rg is not executable, please install it first.')
    return
  endif

  " rg globs
  let ignores = ''
  let includes = ''

  if WINDOWS()
    for ig in conf.ignores
      let ignores .= '-g !'.ig.' '
    endfor

    for ic in conf.includes
      let includes .= '-g '.ic.' '
    endfor
  else
    for ig in conf.ignores
      let ignores .= "-g !'".ig."' "
    endfor

    for ic in conf.includes
      let includes .= "-g '".ic."' "
    endfor
  endif

  " NOTE: includes should be first, then ignores will filter out include results
  let rg_globs = includes . ' ' . ignores

  " set exvim global variables
  let g:exvim_dir = fnamemodify(a:dir, ':p')
  let g:exvim_cwd = fnamemodify(a:dir, ':p:h:h')

  " set parent working directory
  silent exec 'cd ' . fnameescape(g:exvim_cwd)
  let s:old_titlestring = &titlestring
  let &titlestring = "%{g:exvim_cwd}:\ %t\ (%{expand(\"%:p:.:h\")}" . ex#os_sep() . ")"

  " DISABLE: set viewdir
  " NOTE: When the last path part of 'viewdir' does not exist, this directory is created
  " let &viewdir = g:exvim_dir.'view'

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

  " set ex-project
  let g:ex_project_file = fnamemodify(a:dir.'files.exproject', ':p')
  call ex#project#set_filters(conf.ignores, conf.includes)

  " set ex-search
  let g:ex_search_globs = rg_globs

  " set ctrlp
  if g:loaded_ctrlp
    let g:ctrlp_user_command = 'rg %s --no-ignore --hidden --files ' . rg_globs
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
