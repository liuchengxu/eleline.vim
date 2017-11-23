" =============================================================================
" Filename: eleline.vim
" Author: Liu-Cheng Xu
" URL: https://github.com/liuchengxu/eleline.vim
" License: MIT License
" =============================================================================
scriptencoding utf-8
if exists('g:loaded_eleline') || v:version < 700
  finish
endif
let g:loaded_eleline = 1

let s:save_cpo = &cpoptions
set cpoptions&vim

function! s:circled_num(num)
  return nr2char(9311 + a:num)
endfunction

function! S_buf_num()
  let l:nr = bufnr('%')
  return l:nr > 20 ? l:nr : s:circled_num(l:nr).' '
endfunction

function! S_buf_total_num()
  return len(filter(range(1, bufnr('$')), 'buflisted(v:val)'))
endfunction

function! S_file_size(f)
  let l:size = getfsize(expand(a:f))
  if l:size == 0 || l:size == -1 || l:size == -2
    return ''
  endif
  if l:size < 1024
    return l:size.' bytes'
  elseif l:size < 1024*1024
    return printf('%.1f', l:size/1024.0).'k'
  elseif l:size < 1024*1024*1024
    return printf('%.1f', l:size/1024.0/1024.0) . 'm'
  else
    return printf('%.1f', l:size/1024.0/1024.0/1024.0) . 'g'
  endif
endfunction

function! S_full_path()
  if &filetype ==# 'startify'
    return ''
  else
    return expand('%:p:t')
  endif
endfunction

function! S_ale_error()
  if exists('g:loaded_ale')
    let l:counts = ale#statusline#Count(bufnr(''))
      return l:counts[0] == 0 ? '' : '•'.l:counts[0]
  endif
  return ''
endfunction

function! S_ale_warning()
  if exists('g:loaded_ale')
    let l:counts = ale#statusline#Count(bufnr(''))
    return l:counts[1] == 0 ? '' : '•'.l:counts[1]
  endif
  return ''
endfunction

function! S_fugitive()
  if exists('g:loaded_fugitive')
    let l:head = fugitive#head()
    return empty(l:head) ? '' : ' ⎇ '.l:head . ' '
  endif
  return ''
endfunction

function! S_gitgutter()
  if exists('b:gitgutter')
    let l:summary = b:gitgutter.summary
    if l:summary[0] != 0 || l:summary[1] != 0 || l:summary[2] != 0
      return ' +'.l:summary[0].' ~'.l:summary[1].' -'.l:summary[2].' '
    endif
  endif
  return ''
endfunction

" The decoration of statusline was originally stealed from
" https://github.com/junegunn/dotfiles/blob/master/vimrc.
"
" %< Where to truncate
" %n buffer number
" %F Full path
" %m Modified flag: [+], [-]
" %r Readonly flag: [RO]
" %y Type:          [vim]
" fugitive#statusline()
" %= Separator
" %-14.(...)
" %l Line
" %c Column
" %V Virtual column
" %P Percentage
" %#HighlightGroup#

function! MyStatusLine()
  if has('gui_running')
      let l:buf_num = '%1* %n ❖ %{winnr()} %*'
  else
      let l:buf_num = '%1* %{S_buf_num()} ❖ %{winnr()} %*'
  endif
  let l:tot = '%2*[TOT:%{S_buf_total_num()}]%*'
  let l:fs = '%3* %{S_file_size(@%)} %*'
  let l:fp = '%4* %{S_full_path()} %*'
  let l:branch = '%6*%{S_fugitive()}%*'
  let l:gutter = '%{S_gitgutter()}'
  let l:paste = "%#paste#%{&paste?'⎈ paste ':''}%*"
  let l:ale_e = '%#ale_error#%{S_ale_error()}%*'
  let l:ale_w = '%#ale_warning#%{S_ale_warning()}%*'
  let l:m_r_f = '%7* %m%r%y %*'
  let l:pos = '%8* %l:%c%V |'
  let l:enc = " %{''.(&fenc!=''?&fenc:&enc).''} | %{(&bomb?\",BOM\":\"\")}"
  let l:ff = '%{&ff} %*'
  let l:pct = '%9* %P %*'

  return l:buf_num.l:tot.'%<'.l:fs.l:fp.l:branch.l:gutter.l:paste.l:ale_e.l:ale_w.
        \ '%='.l:m_r_f.l:pos.l:enc.l:ff.l:pct
endfunction

" Note that the "%!" expression is evaluated in the context of the
" current window and buffer, while %{} items are evaluated in the
" context of the window that the statusline belongs to.
set statusline=%!MyStatusLine()

let s:colors = {
            \   140 : '#af87d7', 149 : '#99cc66', 171 : '#d75fd7',
            \   178 : '#ffbb7d', 184 : '#ffe920', 208 : '#ff8700',
            \   232 : '#333300', 197 : '#cc0033', 214 : '#ffff66',
            \
            \   235 : '#262626', 236 : '#303030', 237 : '#3a3a3a',
            \   238 : '#444444', 239 : '#4e4e4e', 240 : '#585858',
            \   241 : '#606060', 242 : '#666666', 243 : '#767676',
            \   244 : '#808080', 245 : '#8a8a8a', 246 : '#949494',
            \   247 : '#9e9e9e', 248 : '#a8a8a8', 249 : '#b2b2b2',
            \   250 : '#bcbcbc', 251 : '#c6c6c6', 252 : '#d0d0d0',
            \   253 : '#dadada', 254 : '#e4e4e4', 255 : '#eeeeee',
            \ }

function! s:hi(group, fg, bg, ...)
  execute printf('hi %s ctermfg=%d guifg=%s ctermbg=%d guibg=%s',
                \ a:group, a:fg, s:colors[a:fg], a:bg, s:colors[a:bg])
  if a:0 == 1
    execute printf('hi %s cterm=%s gui=%s', a:group, a:1, a:1)
  endif
endfunction

if !exists('g:eleline_background')
  let s:normal_bg = synIDattr(hlID('Normal'), 'bg', 'cterm')
  if s:normal_bg >= 233 && s:normal_bg <= 243
    let s:bg = s:normal_bg
  else
    let s:bg = 235
  endif
else
  let s:bg = g:eleline_background
endif

" Don't change in gui mode
if has('termguicolors') && &termguicolors
  let s:bg = 235
endif

function! S_statusline_hi()
  call s:hi('User1'      , 232 , 178  )
  call s:hi('User2'      , 178 , s:bg+8 )
  call s:hi('User3'      , 250 , s:bg+6 )
  call s:hi('User4'      , 171 , s:bg+4 , 'bold' )
  call s:hi('User5'      , 208 , s:bg+3 )
  call s:hi('User6'      , 184 , s:bg+2 , 'bold' )

  call s:hi('gutter'      , 184 , s:bg+2)
  call s:hi('paste'       , 149 , s:bg+4)
  call s:hi('ale_error'   , 197 , s:bg+2)
  call s:hi('ale_warning' , 214 , s:bg+2)

  call s:hi('StatusLine' , 140 , s:bg+2 , 'none')

  call s:hi('User7'      , 249 , s:bg+3 )
  call s:hi('User8'      , 250 , s:bg+4 )
  call s:hi('User9'      , 251 , s:bg+5 )
endfunction

" User-defined highlightings shoule be put after colorscheme command.
call S_statusline_hi()

augroup eleline
  autocmd!
  autocmd ColorScheme * call S_statusline_hi()
augroup END

let &cpoptions = s:save_cpo
unlet s:save_cpo
