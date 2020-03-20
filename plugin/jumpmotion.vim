" LICENSE: GPLv3 or later
" AUTHOR: zsugabubus

if exists('g:loaded_jumpmotion')
  finish
endif

let s:save_cpo = &cpo
set cpo&vim

for motion in split('wWbBeEjk(){}*#^_$', '\zs')
  exe 'noremap <Plug>(JumpMotion)' . motion . ' <Cmd>call JumpMotion("' . motion . '")<CR>'
endfor
noremap <Plug>(JumpMotion)[ <Cmd>call JumpMotion('[[')<CR>
noremap <Plug>(JumpMotion)] <Cmd>call JumpMotion(']]')<CR>
noremap <Plug>(JumpMotion)/ <Cmd>call JumpMotion("/\<lt>CR>")<CR>
noremap <Plug>(JumpMotion)? <Cmd>call JumpMotion("?\<lt>CR>")<CR>
nnoremap <Plug>(JumpMotion)i <Cmd>call JumpMotion("!/^\\s*\\zs$\<lt>CR>", 'startinsert')<CR>
nnoremap <Plug>(JumpMotion)o <Cmd>call JumpMotion("!/^\\s*\\zs$\<lt>CR>", 'call feedkeys("o")')<CR>
nnoremap <Plug>(JumpMotion)O <Cmd>call JumpMotion("!/^\\s*\\zs$\<lt>CR>", 'call feedkeys("O")')<CR>
nnoremap <Plug>(JumpMotion)I <Cmd>call JumpMotion("!/^\\s*\\zs\<lt>CR>", 'startinsert')<CR>

try
  call matchdelete(matchaddpos('JumpMotion', []))
catch /No such highlight group name:/
  highlight JumpMotion cterm=bold ctermfg=196 ctermbg=226
endtry

if !exists('*JumpMotionKey')
  function JumpMotionKey(nth) abort
    let alphabet = 'abcdefghijklmnopqrstuvwxyz'
    let nth = a:nth
    let str = ''

    while nth >=# 0
      let str = alphabet[nth % strlen(alphabet)] . str
      let nth = nth / strlen(alphabet) - 1
    endwhile

    return [str, str]
  endfunction
endif

function JumpMotion(motion, ...) abort range
  let motion = a:motion
  let targets = []
  let view = winsaveview()
  let view.bottomline = line('w$')
  let view.rightcol = view.leftcol + winwidth(0) - 1
  let oldlnum = 0
  let oldcol = 0
  let mode = mode()

  " Go to normal mode.
  execute "normal! \<Esc>"

  if motion[0] ==# '!'
    call cursor(view.topline, 0)
    let motion = motion[1:]
  endif

  try
    let oldws = &wrapscan
    let oldve = &virtualedit
    let oldma = &modifiable
    let oldro = &readonly
    let oldspell = &spell

    set nowrapscan virtualedit=all modifiable noreadonly nospell

    while 1
      try
        execute 'normal! ' . motion
      catch
        break
      endtry

      let lnum = line('.')
      let col = col('.')
      let vcol = virtcol('.')

      if lnum ># view.bottomline
        break
      endif

      " No more matches.
      if oldlnum ==# lnum && oldcol ==# col
        if col('$') <=# col + 1 && lnum <# line('$')
          call cursor(lnum + 1, 1)
          continue
        endif

        break
      endif

      " Continue with next line if went out of the screen on the right side.
      if vcol ># view.rightcol
        call cursor(lnum, col('$'))
        continue
      endif

      " Not a closed fold line.
      if foldclosed(lnum) !=# -1
        call cursor(foldclosedend(lnum) + 1, 1)
        continue
      endif

      call add(targets, {
      \  'lnum': lnum,
      \  'col': col + max([vcol - virtcol('$'), 0]),
      \  'vcol': vcol,
      \  'key': g:JumpMotionKey(len(targets))
      \})
      let oldlnum = lnum
      let oldcol = col
    endwhile

    while len(targets) ># 1
      let matches = []
      let oldlnum = 0
      let edit = ''
      let coldiff = 0

      for target in targets
        let keywidth = strdisplaywidth(target.key[1], target.vcol)
        if target.lnum !=# oldlnum
          let coldiff = 0
          let oldlnum = target.lnum
          let line = getline(target.lnum)
        endif
        call add(matches, matchaddpos('JumpMotion', [[target.lnum, target.col + coldiff, strlen(target.key[1])]], 99))
        let coldiff += strlen(target.key[1]) - strlen(strcharpart(strpart(line, target.col - 1), 0, keywidth))
        let edit .= target.lnum . 'G' . target.vcol . '|c' . keywidth . 'l' . escape(target.key[1], '\') . "\<Esc>"
      endfor
      execute 'normal! ' . edit

      call winrestview(view)
      redraw

      try
        " echohl Question
        " echomsg 'Jump to? '
        " echohl None
        let chr = nr2char(getchar())
      catch
        return
      finally
        for match in matches
          call matchdelete(match)
        endfor
        undo
        " Because of undo.
        call winrestview(view)
      endtry

      if chr ==# "\<Esc>"
        return
      elseif chr ==# "\<CR>" || chr ==# ' '
        break
      endif

      call filter(targets, {_, target-> target.key[0][0] ==# chr})
      for target in targets
        let target.key[0] = target.key[0][1:]
        if target.key[0] ==# ''
          let target.key[0] = ' '
        endif
        let target.key[1] = target.key[1][1:]
        if target.key[1] ==# ''
          let target.key[1] = ' '
        endif
      endfor
    endwhile

  finally
    let &wrapscan = oldws
    let &virtualedit = oldve
    let &modifiable = oldma
    let &readonly = oldro
    let &spell = oldspell

    if mode ==? 'v' || mode ==# "\<C-v>"
      normal gv
    endif
  endtry

  try
    let target = targets[0]
  catch
    echohl WarningMsg
    echo 'No matches.'
    echohl None
    return
  endtry

  call setpos('.', [0, target.lnum, target.col])

  execute get(a:, 1, '')
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

let g:loaded_jumpmotion = 1
" vim:ts=2 sw=2 sts=2 tw=72 et fdm=marker
