if version < 600
  syntax clear
elseif exists("b:current_syntax")
  finish
endif

" syntax highlight
syntax match ex_search_help #^".*# contains=ex_search_help_key
syntax match ex_search_help_key '^" \S\+:'hs=s+2,he=e-1 contained contains=ex_search_help_comma
syntax match ex_search_help_comma ':' contained

syntax region ex_search_header start="^----------" end="----------"
syntax region ex_search_filename start="^[^"][^:]*" end=":" oneline
syntax match ex_search_linenr '\d\+:'


hi default link ex_search_help Comment
hi default link ex_search_help_key Label
hi default link ex_search_help_comma Special

hi default link ex_search_header Statement
hi default link ex_search_filename Directory
hi default link ex_search_linenr Number

let b:current_syntax = "exsearch"
