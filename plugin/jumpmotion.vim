" LICENSE: GPLv3 or later
" AUTHOR: zsugabubus

if exists('g:loaded_jumpmotion')
  finish
endif

let s:save_cpo = &cpo
set cpo&vim

if get(g:, 'jumpmotion_do_mappings', 1) && !hasmapto('<Plug>(JumpMotion)')
  for s:lhs in ['<Space>', 's', '<Leader><Leader>', '<Leader><Space>', '<Leader>s']
    if empty(maparg(s:lhs))
      execute 'map <unique>' s:lhs '<Plug>(JumpMotion)'
      break
    endif
  endfor
  unlet s:lhs
endif

if has('nvim')
  command -nargs=+ JumpMotionMap silent! <args>
else
  command -nargs=+ JumpMotionMap
  \  silent! execute substitute('n'.<q-args>, '\V<lt>Cmd>', ':<C-u>let g:jumpmotion_mode="n"<lt>bar>:<C-u>', '')|
  \  silent! execute substitute('x'.<q-args>, '\V<lt>Cmd>', ':<C-u>let g:jumpmotion_mode=visualmode()<lt>CR><lt>bar>:<C-u>', '')|
  \  silent! execute substitute('i'.<q-args>, '\V<lt>Cmd>', ':<C-u>let g:jumpmotion_mode="i"<lt>bar>:<C-u>', '')
endif

for s:motion in split('wWbBeEjk(){}*#,;nN', '\zs')
  execute 'JumpMotionMap noremap <unique> <Plug>(JumpMotion)' . s:motion . ' <Cmd>call JumpMotion("' . s:motion . '")<CR>'
endfor
unlet s:motion

JumpMotionMap noremap  <unique> <Plug>(JumpMotion)g@ :<C-U>set opfunc=<SID>opfunc<CR>g@
JumpMotionMap map      <silent> <Plug>(JumpMotion)v <Plug>(JumpMotion)g@v
JumpMotionMap map      <unique> <Plug>(JumpMotion)d <Plug>(JumpMotion)J
JumpMotionMap map      <unique> <Plug>(JumpMotion)u <Plug>(JumpMotion)K
JumpMotionMap noremap  <unique> <Plug>(JumpMotion)J <Cmd>call JumpMotion('/\v%>' . (line('.') + 9) . 'l%' . virtcol('.') . "v\<lt>CR>")<CR>
JumpMotionMap noremap  <unique> <Plug>(JumpMotion)K <Cmd>call JumpMotion('?\v%<' . (line('.') - 9) . 'l%' . virtcol('.') . "v\<lt>CR>")<CR>
JumpMotionMap noremap  <unique> <Plug>(JumpMotion)[ <Cmd>call JumpMotion('[[')<CR>
JumpMotionMap noremap  <unique> <Plug>(JumpMotion)] <Cmd>call JumpMotion(']]')<CR>
JumpMotionMap map      <silent> <Plug>(JumpMotion)/ <Plug>(JumpMotion)g@/
JumpMotionMap map      <silent> <Plug>(JumpMotion)? <Plug>(JumpMotion)g@?
JumpMotionMap map      <silent> <Plug>(JumpMotion): <Plug>(JumpMotion)g@:
JumpMotionMap noremap  <unique> <Plug>(JumpMotion)f <Cmd>call JumpMotion('f' . nr2char(getchar()))<CR>
JumpMotionMap noremap  <unique> <Plug>(JumpMotion)F <Cmd>call JumpMotion('F' . nr2char(getchar()))<CR>
JumpMotionMap noremap  <unique> <Plug>(JumpMotion)t <Cmd>call JumpMotion('t' . nr2char(getchar()))<CR>
JumpMotionMap noremap  <unique> <Plug>(JumpMotion)T <Cmd>call JumpMotion('T' . nr2char(getchar()))<CR>
JumpMotionMap noremap  <unique> <Plug>(JumpMotion)$ <Cmd>call JumpMotion(':' . line('w0'), "/\\m$\<lt>CR>", '')<CR>
JumpMotionMap noremap  <unique> <Plug>(JumpMotion)_ <Cmd>call JumpMotion(':' . line('w0'), "/\\m^\\s*\\zs\\S\<lt>CR>", '')<CR>
JumpMotionMap noremap  <unique> <Plug>(JumpMotion)% <Cmd>call JumpMotion('%')<CR>
JumpMotionMap noremap  <unique> <Plug>(JumpMotion)g% <Cmd>call JumpMotion('g%')<CR>
JumpMotionMap nnoremap <unique> <Plug>(JumpMotion)i <Cmd>call JumpMotion(':' . line('w0'), "/\\m^\\s*\\zs$\<lt>CR>", 'startinsert')<CR>
JumpMotionMap nnoremap <unique> <Plug>(JumpMotion)I <Cmd>call JumpMotion(':' . line('w0'), "/\\m^\\s*\\zs\<lt>CR>", 'startinsert')<CR>
JumpMotionMap nnoremap <unique> <Plug>(JumpMotion)A <Cmd>call JumpMotion(':' . line('w0'), "/\\m\\S.*\\zs\<lt>CR>", 'startinsert!')<CR>
JumpMotionMap nnoremap <unique> <Plug>(JumpMotion)o <Cmd>call JumpMotion(':' . line('w0'), "/\\m^\\s*\\zs$\<lt>CR>", 'call feedkeys("o")')<CR>
JumpMotionMap nnoremap <unique> <Plug>(JumpMotion)O <Cmd>call JumpMotion(':' . line('w0'), "/\\m^\\s*\\zs$\<lt>CR>", 'call feedkeys("O")')<CR>
" Numbers.
JumpMotionMap nnoremap <unique> <Plug>(JumpMotion)0 <Cmd>call JumpMotion(':' . line('w0'), "/\\v0[xX]\\zs[0-9a-zA-Z]+<bar>0[bB]\\zs[01]+<bar>%(0\\zs)?%(\\d+\\.?)+\<lt>CR>", '')<CR>
" Characters.
JumpMotionMap noremap  <unique> <Plug>(JumpMotion)c <Cmd>call JumpMotion(':' . line('w0'), '/\V' . escape(nr2char(getchar()), '/\') . "\<lt>CR>", '')<CR>
" Two characters.
JumpMotionMap noremap  <unique> <Plug>(JumpMotion)s <Cmd>call JumpMotion(':' . line('w0'), '/\V' . escape(nr2char(getchar()) . nr2char(getchar()), '/\') . "\<lt>CR>", '')<CR>
" Assignments.
JumpMotionMap noremap  <unique> <Plug>(JumpMotion)= <Cmd>call JumpMotion(':' . line('w0'), "/\\m[^~<lt>>=]\\zs=[=#?]\\@!\<lt>CR>", '')<CR>
" Interesting symbols.
JumpMotionMap noremap  <unique> <Plug>(JumpMotion)+ <Cmd>call JumpMotion(':' . line('w0'), "/\\v%([<lt>>!\\-+%*/~&<bar>=,:;(){}[\\]\"'`.]{1,3}%(\\D<bar>$)<bar><%(or<bar>and<bar>not<bar>xor)><bar><begin<bar><end)\<lt>CR>", '')<CR>
" Indentations.
JumpMotionMap noremap  <unique> <Plug>(JumpMotion)> <Cmd>call JumpMotion(':' . line('w0'), "/\\v%(^(\\s*)%($<bar>\\S))@<=.*\\n^\\1\\s+\\zs\<lt>CR>", '')<CR>
" Deindentations.
JumpMotionMap noremap  <unique> <Plug>(JumpMotion)< <Cmd>call JumpMotion(':' . line('w0'), "/\\v^(\\s*)\\s+\\S.*\\n\\1\\zs\\_S\<lt>CR>", '')<CR>
JumpMotionMap map  <unique> <Plug>(JumpMotion)x <Plug>(JumpMotion)g@/0<CR>

delcommand JumpMotionMap

if !hlexists('JumpMotion')
  function s:update_highlights() abort
    highlight JumpMotion     cterm=bold ctermfg=196 ctermbg=226 gui=bold guifg=#ff0000 guibg=#ffff00
  endfunction

  augroup JumpMotionHighlights
    autocmd!
    autocmd ColorScheme * call <SID>update_highlights()
  augroup end

  call s:update_highlights()
endif

if !exists('*JumpMotionKey')
  " Return [{keys-to-press}, {displayed-label}] for @nth match.
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

function! s:noop(type, ...) abort
endfunction

" Vim is fucking dumb.
function! s:opfunc(type) abort
  try
    set opfunc=<SID>noop
    call JumpMotion(':call cursor(0, col(".") + 1)'."\<CR>".'.:call cursor(line("'']"), col("'']"))'."\<CR>")
  finally
    set opfunc=
  endtry
endfunction

" Usage: JumpMotion([{cmd-before} ,] {motion} [, {cmd-after}])
function! JumpMotion(...) abort range
  let before = a:0 >=# 3 ? a:1 : ''
  let motion = a:0 >=# 3 ? a:2 : a:1
  let after  = a:0 >=# 3 ? a:3 : a:0 >=# 2 ? a:1 : ''
  let targets = []
  let view = winsaveview()
  let view.bottomline = line('w$')
  let view.rightcol = view.leftcol + winwidth(0) - 1
  let curlnum = line('.')
  let curcol = col('.')
  let mode = get(g:, 'jumpmotion_mode', mode(1))
  unlet! jumpmotion_mode
  if has('nvim')
    let reg = '.'
  elseif mode ==? 'v' || mode ==# "\<C-v>"
    let reg = line("'<") ==# curlnum ? "'<" : "'>"
    let [curlnum, curcol] = getpos(reg)[1:2]
  else
    let reg = '.'
  endif
  let oldlnum = curlnum
  let oldcol = curcol

  let [oldws, oldcole, oldcocu, oldve, oldlist] =
    \ [&ws, &cole, &cocu, &ve, &list]
  setlocal nowrapscan conceallevel=2 concealcursor=n virtualedit= nolist
  hi! clear Conceal
  hi! link Conceal JumpMotion

  try
    " Go to normal mode.
    execute "normal! \<Esc>"
    execute before

    " Repeat `motion` and generate `targets`.
    while 1
      if exists('l:lnum')
        let oldlnum = lnum
        let oldcol = col
      endif

      try
        keepjumps keeppattern silent execute 'normal' motion
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

      " Ignore match at cursor position.
      if curlnum ==# lnum && curcol ==# col
        let curlnum = 0
        let curcol = 0
        continue
      endif

      " No more matches.
      if oldlnum ==# lnum && oldcol ==# col
        break
      endif

      if !&wrap
        " Skip non-visible part of the screen.
        if view.rightcol <# vcol
          call cursor(lnum, forward ? col('$') : view.rightcol)
          continue
        endif
        if vcol <# view.leftcol
          call cursor(lnum, forward ? view.leftcol : 1)
          continue
        endif
      endif

      " Skip folded lines.
      if foldclosed(lnum) !=# -1
        call cursor(forward ? foldclosedend(lnum) + 1 : foldclosed(lnum) - 1, 1)
        continue
      endif

      let target = {
      \  'lnum': lnum,
      \  'col': col + max([vcol - virtcol('$'), 0]),
      \  'vcol': vcol,
      \  'key': g:JumpMotionKey(len(targets))
      \}
      if !empty(targets) && targets[0].lnum ==# target.lnum && targets[0].col ==# target.col
        " Cycle detected
        break
      endif
      call add(targets, target)
    endwhile

    nohlsearch

    while len(targets) ># 1
      let matches = []

      try
        for target in targets
          let key = target.key[1]
          let col = target.col
          while key != ""
            call add(matches, matchaddpos('Conceal', [
            \  [target.lnum, col, 1]
            \], 99, -1, {'conceal': key}))
            let col += 1
            let key = strcharpart(key, 1)
          endwhile
        endfor

        try
          keepjumps call winrestview(view)
          echo
          redraw
          let chr = nr2char(getchar())
        catch
          unlet targets
          return
        endtry

      catch
        return
      finally
        for match in matches
          call matchdelete(match)
        endfor
      endtry

      if chr ==# "\<Esc>"
        unlet targets
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
    if reg ==# '.' && (mode ==? 'v' || mode ==# "\<C-v>")
      normal gv
    endif

    try
      let target = targets[0]
      call setpos(reg, [0, target.lnum, target.col, 0])
    catch
      echohl ErrorMsg
      echo 'No matches.'
      echohl None
    finally
      " Restore mode.
      if reg !=# '.' && (mode ==? 'v' || mode ==# "\<C-v>")
        normal gv
      elseif mode ==# 'i'
        startinsert " Leave this comment here, otherwise syntax will be messed up.
      elseif mode ==# 'R'
        startreplace
      elseif mode ==# 'Rv'
        startgreplace
      endif
    endtry

    let [&l:ws, &l:cole, &l:cocu, &l:ve, &l:list] =
      \ [oldws, oldcole, oldcocu, oldve, oldlist]
  endtry

  execute after
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

let g:loaded_jumpmotion = 1
" vim:ts=2 sw=2 sts=2 tw=72 et fdm=marker
