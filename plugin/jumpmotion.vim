" LICENSE: GPLv3 or later
" AUTHOR: zsugabubus

if exists('g:loaded_jumpmotion')
  finish
endif

let s:save_cpo = &cpo
set cpo&vim

if !hasmapto('<Plug>(JumpMotion)')
  for lhs in ['<Space>', 's', '<Leader><Leader>', '<Leader><Space>', '<Leader>s']
    if empty(maparg(lhs))
      execute 'map <unique>' lhs '<Plug>(JumpMotion)'
      break
    endif
  endfor
endif

for motion in split('wWbBeEjk(){}*#,;nN', '\zs')
  execute 'noremap <Plug>(JumpMotion)' . motion . ' <Cmd>call JumpMotion("' . motion . '")<CR>'
endfor
map <Plug>(JumpMotion)d <Plug>(JumpMotion)J
map <Plug>(JumpMotion)u <Plug>(JumpMotion)K
noremap <Plug>(JumpMotion)J <Cmd>call JumpMotion('/\v%(^<bar>\S.*)@<=%>' . (line('.') + 9) . 'l%' . virtcol('.') . "v.%(.*\\S<bar>$)@=\<lt>CR>")<CR>
noremap <Plug>(JumpMotion)K <Cmd>call JumpMotion('?\v%(^<bar>\S.*)@<=%<' . (line('.') - 9) . 'l%' . virtcol('.') . "v.%(.*\\S<bar>$)@=\<lt>CR>")<CR>
noremap <Plug>(JumpMotion)[ <Cmd>call JumpMotion('[[')<CR>
noremap <Plug>(JumpMotion)] <Cmd>call JumpMotion(']]')<CR>
noremap <Plug>(JumpMotion)/ <Cmd>call JumpMotion("/\<lt>CR>")<CR>
noremap <Plug>(JumpMotion)? <Cmd>call JumpMotion("?\<lt>CR>")<CR>
noremap <Plug>(JumpMotion)f <Cmd>call JumpMotion('f' . nr2char(getchar()))<CR>
noremap <Plug>(JumpMotion)F <Cmd>call JumpMotion('F' . nr2char(getchar()))<CR>
noremap <Plug>(JumpMotion)t <Cmd>call JumpMotion('t' . nr2char(getchar()))<CR>
noremap <Plug>(JumpMotion)T <Cmd>call JumpMotion('T' . nr2char(getchar()))<CR>
noremap <Plug>(JumpMotion)$ <Cmd>call JumpMotion(':' . line('w0'), "$", '')<CR>
noremap <Plug>(JumpMotion)0 <Cmd>call JumpMotion(':' . line('w0'), "0", '')<CR>
noremap <Plug>(JumpMotion)^ <Cmd>call JumpMotion(':' . line('w0'), "^", '')<CR>
noremap <Plug>(JumpMotion)_ <Cmd>call JumpMotion(':' . line('w0'), "_", '')<CR>
nnoremap <Plug>(JumpMotion)i <Cmd>call JumpMotion(':' . (line('w0') - 1), "/^\\s*\\zs$\<lt>CR>", 'startinsert')<CR>
nnoremap <Plug>(JumpMotion)I <Cmd>call JumpMotion(':' . (line('w0') - 1), "/^\\s*\\zs\<lt>CR>", 'startinsert')<CR>
nnoremap <Plug>(JumpMotion)o <Cmd>call JumpMotion(':' . (line('w0') - 1), "/^\\s*\\zs$\<lt>CR>", 'call feedkeys("o")')<CR>
nnoremap <Plug>(JumpMotion)O <Cmd>call JumpMotion(':' . (line('w0') - 1), "/^\\s*\\zs$\<lt>CR>", 'call feedkeys("O")')<CR>
noremap <Plug>(JumpMotion)p <Cmd>call JumpMotion("/\\V(\<lt>CR>")<CR>
noremap <Plug>(JumpMotion)P <Cmd>call JumpMotion("?\\V(\<lt>CR>")<CR>
noremap <Plug>(JumpMotion)b <Cmd>call JumpMotion("/\\V{\<lt>CR>")<CR>
noremap <Plug>(JumpMotion)B <Cmd>call JumpMotion("?\\V{\<lt>CR>")<CR>
noremap <Plug>(JumpMotion), <Cmd>call JumpMotion("/,\<lt>CR>")<CR>
noremap <Plug>(JumpMotion)= <Cmd>call JumpMotion("/\\<=\<lt>CR>")<CR>
noremap <Plug>(JumpMotion)c <Cmd>call JumpMotion(':' . (line('w0') - 1), '/\V' . escape(nr2char(getchar()), '/\') . "\<lt>CR>", '')<CR>
noremap <Plug>(JumpMotion)s <Cmd>call JumpMotion(':' . (line('w0') - 1), '/\V' . escape(nr2char(getchar()) . nr2char(getchar()), '/\') . "\<lt>CR>", '')<CR>

try
  call matchdelete(matchaddpos('JumpMotion', []))
catch /No such highlight group name:/
  highlight JumpMotion     cterm=bold ctermfg=196 ctermbg=226
  highlight JumpMotionTail cterm=NONE ctermfg=196 ctermbg=226
endtry

if !exists('*JumpMotionKey')
  " [{keys to press}, {displayed label}] for @nth match.
  function JumpMotionKey(nth) abort
    let alphabet = get(g:, 'jumpmotion_abc', 'abcdefghijklmnopqrstuvwxyz')
    let nth = a:nth
    let str = ''

    while nth >=# 0
      let str = alphabet[nth % strlen(alphabet)] . str
      let nth = nth / strlen(alphabet) - 1
    endwhile

    return [str, str]
  endfunction
endif

" JumpMotion([cmd-before ,] {motion} [, cmd-after])
function JumpMotion(...) abort range
  let before = a:0 >=# 3 ? a:1 : ''
  let motion = a:0 >=# 3 ? a:2 : a:1
  let after  = a:0 >=# 3 ? a:3 : a:0 >=# 2 ? a:1 : ''
  let targets = []
  let view = winsaveview()
  let view.bottomline = line('w$')
  let view.rightcol = view.leftcol + winwidth(0) - 1
  let oldlnum = line('.')
  let oldcol = col('.')
  let mode = mode()

  " Go to normal mode.
  execute "normal! \<Esc>"
  execute before

  try
    let oldws = &wrapscan
    let oldve = &virtualedit
    let oldma = &modifiable
    let oldro = &readonly
    let oldspell = &spell
    let oldul = &undolevels
    let oldmod = &modified

    set nowrapscan virtualedit=all modifiable noreadonly nospell
    if oldul ==# 0
      " Otherwise don’t touch it.
      set undolevels=1
    endif

    while 1
      if exists('l:lnum')
        let oldlnum = lnum
        let oldcol = col
      endif

      try
        keepjumps keeppattern silent execute 'normal! ' . motion
      catch
        break
      endtry

      let lnum = line('.')
      let col = col('.')
      let vcol = virtcol('.')

      let forward = !(lnum <# oldlnum || (lnum ==# oldlnum && col <# oldcol))

      if lnum <# view.topline || view.bottomline <# lnum
        break
      endif

      " No more matches.
      if oldlnum ==# lnum && oldcol ==# col
        let linewant = lnum + (forward ? 1 : -1)
        call cursor(linewant, (forward ? 1 : view.rightcol))
        if line('.') !=# linewant
          break
        endif
        continue
      endif

      " Skip non-visible part of the screen.
      if view.rightcol <# vcol
        call cursor(lnum, forward ? col('$') : view.rightcol)
        continue
      endif
      if vcol <# view.leftcol
        call cursor(lnum, forward ? view.leftcol : 1)
        continue
      endif

      " Skip folded lines.
      if foldclosed(lnum) !=# -1
        call cursor(forward ? foldclosedend(lnum) + 1 : foldclosed(lnum) - 1, 1)
        continue
      endif

      call add(targets, {
      \  'lnum': lnum,
      \  'col': col + max([vcol - virtcol('$'), 0]),
      \  'vcol': vcol,
      \  'key': g:JumpMotionKey(len(targets))
      \})
    endwhile

    try
      let undofile = undofile(expand('%'))
      let deleundofile = !empty(&buftype)
      execute 'wundo!' fnameescape(undofile)
    catch
      try
        let undofile = tempname()
        let deleundofile = 1
        execute 'wundo!' fnameescape(undofile)
      catch /Invalid in command-line window;/
        unlet! undofile
      endtry
    endtry

    nohlsearch

    while len(targets) ># 1
      let matches = []
      " Sequence of edit commands that add key labels to buffer.
      let edit = ''
      let oldlnum = 0
      " Wanted and real difference in columns due to byte length
      " differences between key labels and text that will be
      " overwritten.
      let coldiff = 0

      try
        for target in targets
          let keywidth = strdisplaywidth(target.key[1], target.vcol)
          if target.lnum !=# oldlnum
            let coldiff = 0
            let oldlnum = target.lnum
            let line = getline(target.lnum)
          endif

          let keyheadlen = strlen(strcharpart(target.key[1], 0, 1))
          call add(matches, matchaddpos('JumpMotion', [
          \  [target.lnum, target.col + coldiff, keyheadlen]
          \], 99))

          let keytaillen = strlen(strcharpart(target.key[1], 1))
          if keytaillen ># 0
            call add(matches, matchaddpos('JumpMotionTail', [
            \  [target.lnum, target.col + coldiff + keyheadlen, keytaillen]
            \], 99))
          endif

          let oldtext = strcharpart(strpart(line, target.col - 1), 0, keywidth)
          let coldiff += strlen(target.key[1]) - strlen(oldtext)
          let edit .= target.lnum . 'G' . target.vcol . '|"_c' . keywidth . 'l' . escape(target.key[1], '\') . "\<Esc>"
        endfor

        try
          keepjumps execute 'normal! ' . edit

          keepjumps call winrestview(view)
          let &modified = oldmod
          redraw

          let chr = nr2char(getchar())
        catch
          return
        finally
          silent undo
        endtry

      catch
        return
      finally
        for match in matches
          call matchdelete(match)
        endfor
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
    let &undolevels = oldul

    if mode ==? 'v' || mode ==# "\<C-v>"
      normal gv
    endif

    if exists('undofile')
      try
        silent execute 'rundo' fnameescape(undofile)
      catch /Invalid in command-line window;/
      endtry
      if deleundofile
        call delete(undofile)
      endif
    endif

    keepjumps call winrestview(view)
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

  execute after
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

let g:loaded_jumpmotion = 1
" vim:ts=2 sw=2 sts=2 tw=72 et fdm=marker
