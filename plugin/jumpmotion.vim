if exists('g:loaded_jumpmotion')
	finish
endif

silent! map <unique> <space> <Plug>(JumpMotion)
map <Plug>(JumpMotion) <Cmd>set opfunc=v:lua.jumpmotion_opfunc<CR>g@v

augroup JumpMotionHighlights
	autocmd!
	autocmd ColorScheme *
		\ highlight default JumpMotionHead cterm=bold ctermfg=196 ctermbg=226 gui=bold guifg=#ff0000 guibg=#ffff00|
		\ highlight default JumpMotionTail            ctermfg=196 ctermbg=226          guifg=#ff0000 guibg=#ffff00
augroup END

lua require'jumpmotion'

let g:loaded_jumpmotion = 1
