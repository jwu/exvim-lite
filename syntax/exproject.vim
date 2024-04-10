if version < 600
  syntax clear
elseif exists("b:current_syntax")
  finish
endif

" syntax highlight
syntax match ex_pj_help #^".*# contains=ex_pj_help_key
syntax match ex_pj_help_key '^" \S\+:'hs=s+2,he=e-1 contained contains=ex_pj_help_comma
syntax match ex_pj_help_comma ':' contained

syntax match ex_pj_fold '{\|}'
syntax match ex_pj_tree_line '\(|\)\+\s\?-\?.*' contains=ex_pj_folder_name,ex_pj_file_name

syntax match ex_pj_folder_label '\C\[F\]'
syntax match ex_pj_folder_name '\C\[F\].*'hs=s+3 contains=ex_pj_folder_label,ex_pj_fold

syntax match ex_pj_file_name '|-[^\[]\+'ms=s+2 contains=ex_pj_fold

hi default link ex_pj_help Comment
hi default link ex_pj_help_key Label
hi default link ex_pj_help_comma Special

hi default link ex_pj_fold EX_TRANSPARENT
" hi default link ex_pj_tree_line Comment
hi default link ex_pj_tree_line SpecialKey

" hi default link ex_pj_folder_label Title
hi default link ex_pj_folder_label Error
hi default link ex_pj_folder_name Directory

" hi default link ex_pj_file_name Normal
hi ex_pj_file_name ctermbg=NONE guibg=NONE

let b:current_syntax = "exproject"
