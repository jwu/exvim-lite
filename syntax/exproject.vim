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
syntax match ex_pj_tree_line '\( |\)\+-\{0,1}.*' contains=ex_pj_folder_name,ex_pj_file_name

syntax match ex_pj_folder_label '\C\[F\]'
syntax match ex_pj_folder_name '\C\[F\].*'hs=s+3 contains=ex_pj_folder_label,ex_pj_fold

syntax match ex_pj_file_name '|-[^\[]\+'ms=s+2 contains=@ex_pj_special_files,ex_pj_fold

" filetypes
syntax match ex_pj_ft_clang_src '.*\.\(c\|cpp\|cxx\|cs\)\>' contained
syntax match ex_pj_ft_clang_header '.*\.\(h\)\>' contained
syntax match ex_pj_ft_script '.*\.\(js\|ts\|lua\|py\)\>' contained
syntax match ex_pj_ft_html '.*\.\(html\|xml\|json\)\>' contained
syntax match ex_pj_ft_css '.*\.\(css\|styl\|less\|sass\)\>' contained

" special
syntax match ex_pj_ft_exvim '.*\.\(exvim\|vimentry\|vimproject\)\>' contained
syntax match ex_pj_ft_error '.*\.\(err\)\>' contained
syntax match ex_pj_ft_special 'package\.json' contained

syntax cluster ex_pj_special_files contains=
      \ex_pj_ft_clang_src
      \,ex_pj_ft_clang_header
      \,ex_pj_ft_script
      \,ex_pj_ft_html
      \,ex_pj_ft_css
      \,ex_pj_ft_exvim
      \,ex_pj_ft_error
      \,ex_pj_ft_special


hi default link ex_pj_help Comment
hi default link ex_pj_help_key Label
hi default link ex_pj_help_comma Special

hi default link ex_pj_fold EX_TRANSPARENT
" hi default link ex_pj_tree_line Comment
hi default link ex_pj_tree_line SpecialKey

" hi default link ex_pj_folder_label Title
hi default link ex_pj_folder_label Error
hi default link ex_pj_folder_name Directory

hi default link ex_pj_file_name Normal

hi default link ex_pj_ft_clang_src Normal
hi default link ex_pj_ft_clang_header Normal
hi default link ex_pj_ft_script Normal
hi default link ex_pj_ft_html Label
hi default link ex_pj_ft_css Label

hi default link ex_pj_ft_exvim DiffAdd
hi default link ex_pj_ft_error Error
hi default link ex_pj_ft_special DiffChange

let b:current_syntax = "exproject"
