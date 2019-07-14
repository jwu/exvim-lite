" ex#conf#new {{{
function ex#conf#new(file)
  let lines = [
        \ '{',
        \ '  "version": "1.0.0",',
        \ '  "files.exclude": [',
        \ '    "**/.git",',
        \ '    "**/.svn",',
        \ '    "**/.exvim"',
        \ '  ],',
        \ '  "space": 2',
        \ '}'
        \ ]
  call writefile(lines, a:file)
endfunction

" ex#conf#load {{{
function ex#conf#load(file)
endfunction

" ex#conf#apply {{{
function ex#conf#apply(conf)
endfunction
