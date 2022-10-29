if exists('loaded_jumpmotion')
	finish
endif
let loaded_jumpmotion = 1

silent! map <unique> <space> <Plug>(JumpMotion)
map <Plug>(JumpMotion) <Cmd>set opfunc=v:lua.jumpmotion_opfunc<CR>g@v

augroup jumpmotion
	autocmd! ColorScheme *
		\ highlight default JumpMotionHead cterm=bold ctermfg=196 ctermbg=226 gui=bold guifg=#ff0000 guibg=#ffff00|
		\ highlight default JumpMotionTail            ctermfg=196 ctermbg=226          guifg=#ff0000 guibg=#ffff00
	doautocmd jumpmotion ColorScheme
augroup END

lua require 'jumpmotion'
