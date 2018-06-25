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

let s:font = get(g:, 'eleline_powerline_fonts', get(g:, 'airline_powerline_fonts', 0))
let s:jobs = {}

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

function! s:is_tmp_file()
  if !empty(&buftype) | return 1 | endif
  if &filetype ==# 'gitcommit' | return 1 | endif
  if expand('%:p') =~# '^/tmp' | return 1 | endif
endfunction

" Reference: https://github.com/chemzqm/vimrc/blob/master/statusline.vim
function! S_fugitive(...) abort
  if s:is_tmp_file() | return | endif
  let reload = get(a:, 1, 0) == 1
  if exists('b:eleline_branch') && !reload | return b:eleline_branch | endif
  if !exists('*FugitiveExtractGitDir') | return '' | endif
  let roots = values(s:jobs)
  let dir = get(b:, 'git_dir', FugitiveExtractGitDir(resolve(expand('%:p'))))
  if empty(dir) | return '' | endif
  let b:git_dir = dir
  let root = fnamemodify(dir, ':h')
  if index(roots, root) >= 0 | return '' | endif

  let argv = has('win32') ? ['cmd', '/c', 'git branch'] : ['bash', '-c', 'git branch']
  if exists('*job_start')
    let job = job_start(argv, {'out_io': 'pipe', 'err_io':'null',  'out_cb': function('s:branch')})
    if job_status(job) == 'fail' | return '' | endif
    let s:cwd = root
    let job_id = matchstr(job, '\d\+')
    let s:jobs[job_id] = root
  elseif exists('*jobstart')
    let job_id = jobstart(argv, {
      \ 'cwd': root,
      \ 'stdout_buffered': v:true,
      \ 'stderr_buffered': v:true,
      \ 'on_exit': function('s:JobHandler')
      \})
    if job_id == 0 || job_id == -1 | return '' | endif
    let s:jobs[job_id] = root
  elseif exists('g:loaded_fugitive')
    let l:head = fugitive#head()
    let l:symbol = s:font ? " \ue0a0 " : ' ⎇ '
    return empty(l:head) ? '' : l:symbol.l:head . ' '
  endif

  return ''
endfunction

function! s:branch(channel, message) abort
  if a:message =~ "^* "
    let l:job = ch_getjob(a:channel)
    let l:job_id = matchstr(string(l:job), '\d\+')
    if !has_key(s:jobs, l:job_id) | return | endif
    let l:branch = substitute(a:message, '*', s:font ? " \ue0a0" : ' ⎇ ', '')
    call s:SetGitStatus(s:cwd, l:branch.' ')
    call remove(s:jobs, l:job_id)
  endif
endfunction

function! s:JobHandler(job_id, data, event) dict abort
  if !has_key(s:jobs, a:job_id) | return | endif
  if v:dying | return | endif
  let l:cur_branch = join(filter(self.stdout, 'v:val =~ "*"'))
  if !empty(l:cur_branch)
    let l:branch = substitute(l:cur_branch, '*', s:font ? " \ue0a0" : ' ⎇ ', '')
    call s:SetGitStatus(self.cwd, l:branch.' ')
  else
    let errs = join(self.stderr)
    if !empty(errs) | echoerr errs | endif
  endif
  call remove(s:jobs, a:job_id)
endfunction

function! s:SetGitStatus(root, str)
  let buf_list = filter(range(1, bufnr('$')), 'bufexists(v:val)')
  for nr in buf_list
    let path = fnamemodify(bufname(nr), ':p')
    if match(path, a:root) >= 0
      call setbufvar(nr, 'eleline_branch', a:str)
    endif
  endfor
  redraws!
endfunction

function! S_gitgutter()
  if exists('b:gitgutter')
    let l:summary = get(b:gitgutter, 'summary', [0, 0, 0])
    if l:summary[0] != 0 || l:summary[1] != 0 || l:summary[2] != 0
      return ' +'.l:summary[0].' ~'.l:summary[1].' -'.l:summary[2].' '
    endif
  endif
  return ''
endfunction

function! S_gutentags()
  if exists('b:gutentags_files')
    return gutentags#statusline()
  endif
  return ''
endfunction

" https://github.com/liuchengxu/eleline.vim/wiki
function! s:MyStatusLine()
  let l:buf_num = '%1* '.(has('gui_running')?'%n':'%{S_buf_num()}')." ❖ %{winnr()} %*"
  let l:paste = "%#paste#%{&paste?'PASTE ':''}%*"
  let l:tot = '%2*[TOT:%{S_buf_total_num()}]%*'
  let l:fs = '%3* %{S_file_size(@%)} %*'
  let l:fp = '%4* %{S_full_path()} %*'
  let l:branch = '%6*%{S_fugitive()}%*'
  let l:gutter = '%{S_gitgutter()}'
  let l:ale_e = '%#ale_error#%{S_ale_error()}%*'
  let l:ale_w = '%#ale_warning#%{S_ale_warning()}%*'
  let l:tags = '%{S_gutentags()}'
  let l:m_r_f = '%7* %m%r%y %*'
  let l:pos = '%8* '.(s:font?"\ue0a1":'').'%l/%L:%c%V |'
  let l:enc = " %{''.(&fenc!=''?&fenc:&enc).''} | %{(&bomb?\",BOM\":\"\")}"
  let l:ff = '%{&ff} %*'
  let l:pct = '%9* %P %*'

  return l:buf_num.l:paste.l:tot.'%<'.l:fs.l:fp.l:branch.l:gutter.l:ale_e.l:ale_w.
        \ '%='.l:tags.l:m_r_f.l:pos.l:enc.l:ff.l:pct
endfunction

let s:colors = {
            \   140 : '#af87d7', 149 : '#99cc66', 160 : '#d70000',
            \   171 : '#d75fd7', 178 : '#ffbb7d', 184 : '#ffe920',
            \   208 : '#ff8700', 232 : '#333300', 197 : '#cc0033',
            \   214 : '#ffff66',
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
  let s:normal_bg = synIDattr(synIDtrans(hlID('Normal')), "bg", 'cterm')
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

function! s:hi_statusline()
  call s:hi('User1'      , 232 , 178  )
  call s:hi('paste'      , 232 , 178    , 'bold')
  call s:hi('User2'      , 178 , s:bg+8 )
  call s:hi('User3'      , 250 , s:bg+6 )
  call s:hi('User4'      , 171 , s:bg+4 , 'bold' )
  call s:hi('User5'      , 208 , s:bg+3 )
  call s:hi('User6'      , 184 , s:bg+2 , 'bold' )

  call s:hi('gutter'      , 184 , s:bg+2)
  call s:hi('ale_error'   , 197 , s:bg+2)
  call s:hi('ale_warning' , 214 , s:bg+2)

  call s:hi('StatusLine' , 140 , s:bg+2 , 'none')

  call s:hi('User7'      , 249 , s:bg+3 )
  call s:hi('User8'      , 250 , s:bg+4 )
  call s:hi('User9'      , 251 , s:bg+5 )
endfunction

function! s:InsertStatuslineColor(mode)
  if a:mode == 'i'
    call s:hi('User1' , 251 , s:bg+8 )
  elseif a:mode == 'r'
    call s:hi('User1' , 232 ,  160 )
  else
    call s:hi('User1' , 232 , 178  )
  endif
endfunction

" Note that the "%!" expression is evaluated in the context of the
" current window and buffer, while %{} items are evaluated in the
" context of the window that the statusline belongs to.
function! SetMyStatusline(...) abort
  call S_fugitive(1)
  let &l:statusline = s:MyStatusLine()
  " User-defined highlightings shoule be put after colorscheme command.
  call s:hi_statusline()
endfunction

if exists('*timer_start')
  call timer_start(100, 'SetMyStatusline')
else
  call SetMyStatusline()
endif

augroup eleline
  autocmd!
  " Change colors for insert mode
  autocmd InsertLeave * call s:hi('User1' , 232 , 178  )
  autocmd InsertEnter,InsertChange * call s:InsertStatuslineColor(v:insertmode)
  autocmd BufWinEnter,ShellCmdPost,BufWritePost * call SetMyStatusline()
  autocmd FileChangedShellPost,ColorScheme * call SetMyStatusline()
  autocmd FileReadPre,ShellCmdPost,FileWritePost * call SetMyStatusline()
augroup END

let &cpoptions = s:save_cpo
unlet s:save_cpo
