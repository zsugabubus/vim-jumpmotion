" LICENSE: GPLv3 or later
" AUTHOR: zsugabubus

if exists('g:loaded_jumpmotion')
  finish
endif

let s:save_cpo = &cpo
set cpo&vim

if !hasmapto('<Plug>(JumpMotion)')
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
  " We lose functionality but cannot come up with a solution that could
  " move cursor in visual mode in Vim. So just replace <Cmd> with :.
  command -nargs=+ JumpMotionMap silent! execute substitute(<q-args>, '\V<lt>Cmd>', ':', '')
endif

for s:motion in split('wWbBeEjk(){}*#,;nN', '\zs')
  execute 'JumpMotionMap noremap <unique> <Plug>(JumpMotion)' . s:motion . ' <Cmd>call JumpMotion("' . s:motion . '")<CR>'
endfor
unlet s:motion
JumpMotionMap map      <unique> <Plug>(JumpMotion)d <Plug>(JumpMotion)J
JumpMotionMap map      <unique> <Plug>(JumpMotion)u <Plug>(JumpMotion)K
JumpMotionMap noremap  <unique> <Plug>(JumpMotion)J <Cmd>call JumpMotion('/\v%(^<bar>\S.*)@<=%>' . (line('.') + 9) . 'l%' . virtcol('.') . "v.%(.*\\S<bar>$)@=\<lt>CR>")<CR>
JumpMotionMap noremap  <unique> <Plug>(JumpMotion)K <Cmd>call JumpMotion('?\v%(^<bar>\S.*)@<=%<' . (line('.') - 9) . 'l%' . virtcol('.') . "v.%(.*\\S<bar>$)@=\<lt>CR>")<CR>
JumpMotionMap noremap  <unique> <Plug>(JumpMotion)[ <Cmd>call JumpMotion('[[')<CR>
JumpMotionMap noremap  <unique> <Plug>(JumpMotion)] <Cmd>call JumpMotion(']]')<CR>
JumpMotionMap noremap  <unique> <Plug>(JumpMotion)/ <Cmd>call JumpMotion("/\<lt>CR>")<CR>
JumpMotionMap noremap  <unique> <Plug>(JumpMotion)? <Cmd>call JumpMotion("?\<lt>CR>")<CR>
JumpMotionMap noremap  <unique> <Plug>(JumpMotion)f <Cmd>call JumpMotion('f' . nr2char(getchar()))<CR>
JumpMotionMap noremap  <unique> <Plug>(JumpMotion)F <Cmd>call JumpMotion('F' . nr2char(getchar()))<CR>
JumpMotionMap noremap  <unique> <Plug>(JumpMotion)t <Cmd>call JumpMotion('t' . nr2char(getchar()))<CR>
JumpMotionMap noremap  <unique> <Plug>(JumpMotion)T <Cmd>call JumpMotion('T' . nr2char(getchar()))<CR>
JumpMotionMap noremap  <unique> <Plug>(JumpMotion)$ <Cmd>call JumpMotion(':' . line('w0'), "/\\m$\<lt>CR>", '')<CR>
JumpMotionMap noremap  <unique> <Plug>(JumpMotion)_ <Cmd>call JumpMotion(':' . line('w0'), "/\\m^\\s*\\zs\\S\<lt>CR>", '')<CR>
JumpMotionMap nnoremap <unique> <Plug>(JumpMotion)i <Cmd>call JumpMotion(':' . line('w0'), "/\\m^\\s*\\zs$\<lt>CR>", 'startinsert')<CR>
JumpMotionMap nnoremap <unique> <Plug>(JumpMotion)I <Cmd>call JumpMotion(':' . line('w0'), "/\\m^\\s*\\zs\<lt>CR>", 'startinsert')<CR>
JumpMotionMap nnoremap <unique> <Plug>(JumpMotion)A <Cmd>call JumpMotion(':' . line('w0'), "/\\m\\S.*\\zs\<lt>CR>", 'startinsert!')<CR>
JumpMotionMap nnoremap <unique> <Plug>(JumpMotion)o <Cmd>call JumpMotion(':' . line('w0'), "/\\m^\\s*\\zs$\<lt>CR>", 'call feedkeys("o")')<CR>
JumpMotionMap nnoremap <unique> <Plug>(JumpMotion)O <Cmd>call JumpMotion(':' . line('w0'), "/\\m^\\s*\\zs$\<lt>CR>", 'call feedkeys("O")')<CR>
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

delcommand JumpMotionMap

if !hlexists('JumpMotion')
  function s:update_highlights() abort
    highlight JumpMotion     cterm=bold ctermfg=196 ctermbg=226 gui=bold guifg=#ff0000 guibg=#ffff00
    highlight JumpMotionTail cterm=NONE ctermfg=196 ctermbg=226 gui=NONE guifg=#ff0000 guibg=#ffff00
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

" Usage: JumpMotion([cmd-before ,] {motion} [, cmd-after])
function JumpMotion(...) abort range
  let before = a:0 >=# 3 ? a:1 : ''
  let motion = a:0 >=# 3 ? a:2 : a:1
  let after  = a:0 >=# 3 ? a:3 : a:0 >=# 2 ? a:1 : ''
  let targets = []
  let view = winsaveview()
  let view.bottomline = line('w$')
  let view.rightcol = view.leftcol + winwidth(0) - 1
  let curlnum = line('.')
  let curcol = col('.')
  let oldlnum = curlnum
  let oldcol = curcol
  let mode = mode(1)

  let oldws = &wrapscan
  let oldve = &virtualedit
  let oldma = &modifiable
  let oldro = &readonly
  let oldspell = &spell
  let oldul = &undolevels
  let oldmod = &modified

  setlocal nowrapscan virtualedit=all modifiable noreadonly nospell
  " Add one extra undo level for two reasons:
  " - If undo file could not be created, we can push out a history entry
  "   if history is full.
  " - Ensure we can use :undo even if user set -1 (no history at all).
  let &l:undolevels=oldul + 1

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

      call add(targets, {
      \  'lnum': lnum,
      \  'col': col + max([vcol - virtcol('$'), 0]),
      \  'vcol': vcol,
      \  'key': g:JumpMotionKey(len(targets))
      \})
    endwhile

    nohlsearch

    if undotree().seq_last ># 0
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
    else
      " History is empty but we need :undo.
      setlocal undolevels=0
    endif

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
            let edit .= target.lnum . 'G'
          endif

          let keyheadlen = strlen(strcharpart(target.key[1], 0, 1))
          call add(matches, matchaddpos('JumpMotion', [
          \  [target.lnum, target.col + coldiff, keyheadlen]
          \], 99))

          let keytaillen = strlen(strcharpart(target.key[1], 1))
          if keytaillen ># 0 && hlexists('JumpMotionTail')
            call add(matches, matchaddpos('JumpMotionTail', [
            \  [target.lnum, target.col + coldiff + keyheadlen, keytaillen]
            \], 99))
          endif

          let oldtext = strcharpart(strpart(line, target.col - 1), 0, keywidth)
          let coldiff += strlen(target.key[1]) - strlen(oldtext)
          let edit .= target.vcol . '|gR' . target.key[1] . "\<Esc>"
        endfor

        try
          noautocmd keepjumps execute 'normal!' edit

          keepjumps call winrestview(view)
          let &l:modified = oldmod
          redraw

          let chr = nr2char(getchar())
        catch
          unlet targets
          return
        finally
          noautocmd silent undo
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
    if exists('undofile')
      try
        silent execute 'rundo' fnameescape(undofile)
      catch /Invalid in command-line window;/
      endtry
      if deleundofile
        call delete(undofile)
      endif
    elseif &undolevels ==# 0
      " Clear all history. We only do this if there was no undo history,
      " or original 'undolevels' was -1.
      setlocal undolevels=-1
      " Do some idempotent change.
      noautocmd call setline(1, getline(1))
    endif

    keepjumps call winrestview(view)

    try
      let target = targets[0]
      call cursor(target.lnum, target.col)
    catch
      echohl ErrorMsg
      echo 'No matches.'
      echohl None
    endtry

    if mode ==? 'v' || mode ==# "\<C-v>"
      normal gv
    elseif mode ==# 'i'
      startinsert " Leave this comment here, otherwise syntax will be messed up.
    elseif mode ==# 'R'
      startreplace
    elseif mode ==# 'Rv'
      startgreplace
    endif

    let &l:wrapscan = oldws
    let &l:virtualedit = oldve
    let &l:modifiable = oldma
    let &l:readonly = oldro
    let &l:spell = oldspell
    let &l:undolevels = oldul
    let &l:modified = oldmod
  endtry

  execute after
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

let g:loaded_jumpmotion = 1
" vim:ts=2 sw=2 sts=2 tw=72 et fdm=marker
