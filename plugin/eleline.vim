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

function! s:circled_num(num) abort
  return nr2char(9311 + a:num)
endfunction

function! ElelineBufnrWinnr() abort
  if has('gui_running')
    let l:bufnr = '%n'
  else
    let l:bufnr = bufnr('%')
    let l:bufnr = l:bufnr > 20 ? l:bufnr : s:circled_num(l:bufnr).' '
  endif
  return '  '.l:bufnr." ❖ ".winnr().' '
endfunction

function! ElelineBufNr() abort
  return '[TOT:'.len(filter(range(1, bufnr('$')), 'buflisted(v:val)')).']'
endfunction

function! ElelinePaste() abort
  return &paste ? 'PASTE ' : ''
endfunction

function! ElelineFsize(f)
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

function! ElelineCurFname()
  return &filetype ==# 'startify' ? '' : ' '.expand('%:p:t').' '
endfunction

function! ElelineError()
  if exists('g:loaded_ale')
    let l:counts = ale#statusline#Count(bufnr(''))
      return l:counts[0] == 0 ? '' : '•'.l:counts[0].' '
  endif
  return ''
endfunction

function! ElelineWarning()
  if exists('g:loaded_ale')
    let l:counts = ale#statusline#Count(bufnr(''))
    return l:counts[1] == 0 ? '' : '•'.l:counts[1].' '
  endif
  return ''
endfunction

function! s:is_tmp_file()
  if !empty(&buftype) | return 1 | endif
  if index(['startify', 'gitcommit'], &filetype) > -1 | return 1 | endif
  if expand('%:p') =~# '^/tmp' | return 1 | endif
endfunction

" Reference: https://github.com/chemzqm/vimrc/blob/master/statusline.vim
function! ElelineGitBranch(...) abort
  if s:is_tmp_file() | return '' | endif
  let reload = get(a:, 1, 0) == 1
  if exists('b:eleline_branch') && !reload | return b:eleline_branch | endif
  if !exists('*FugitiveExtractGitDir') | return '' | endif
  let roots = values(s:jobs)
  let dir = get(b:, 'git_dir', FugitiveExtractGitDir(resolve(expand('%:p'))))
  if empty(dir) | return '' | endif
  let b:git_dir = dir
  let root = fnamemodify(dir, ':h')
  if index(roots, root) >= 0 | return '' | endif

  let argv = add(has('win32') ? ['cmd', '/c']: ['bash', '-c'], 'git branch')
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
    let l:symbol = s:font ? " \ue0a0 " : ' Git:'
    return empty(l:head) ? '' : l:symbol.l:head . ' '
  endif

  return ''
endfunction

function! s:branch(channel, message) abort
  if a:message =~ "^* "
    let l:job = ch_getjob(a:channel)
    let l:job_id = matchstr(string(l:job), '\d\+')
    if !has_key(s:jobs, l:job_id) | return | endif
    let l:branch = substitute(a:message, '*', s:font ? "  \ue0a0" : ' Git:', '')
    call s:SetGitBranch(s:cwd, l:branch.' ')
    call remove(s:jobs, l:job_id)
  endif
endfunction

function! s:JobHandler(job_id, data, event) dict abort
  if !has_key(s:jobs, a:job_id) | return | endif
  if v:dying | return | endif
  let l:cur_branch = join(filter(self.stdout, 'v:val =~ "*"'))
  if !empty(l:cur_branch)
    let l:branch = substitute(l:cur_branch, '*', s:font ? "  \ue0a0" : ' Git:', '')
    call s:SetGitBranch(self.cwd, l:branch.' ')
  else
    let errs = join(self.stderr)
    if !empty(errs) | echoerr errs | endif
  endif
  call remove(s:jobs, a:job_id)
endfunction

function! s:SetGitBranch(root, str)
  let buf_list = filter(range(1, bufnr('$')), 'bufexists(v:val)')
  let root = a:root
  for nr in buf_list
    let path = fnamemodify(bufname(nr), ':p')
    if has('win32')
      let path = substitute(path, '\', '/', 'g')
      let root = substitute(root, '\', '/', 'g')
    endif
    if match(path, a:root) >= 0
      call setbufvar(nr, 'eleline_branch', a:str)
    endif
  endfor
  redraws!
endfunction

function! ElelineGitStatus()
  let l:summary = [0, 0, 0]
  if exists('b:sy')
    let l:summary = b:sy.stats
  elseif exists('b:gitgutter.summary')
    let l:summary = b:gitgutter.summary
  endif
  if max(l:summary) > 0
    return ' +'.l:summary[0].' ~'.l:summary[1].' -'.l:summary[2].' '
  endif
  return ''
endfunction

function! S_gutentags()
  if exists('b:gutentags_files')
    return gutentags#statusline()
  endif
  return ''
endfunction

" Inspired by: https://github.com/chemzqm/tstool.nvim
let s:frames = ['◐', '◑', '◒', '◓']
let s:frame_index = 0
let s:lcn = s:frames[0]

function! s:OnFrame(...) abort
  let s:lcn = s:frames[s:frame_index]
  let s:frame_index += 1
  let s:frame_index = s:frame_index % len(s:frames)
  " When the server is idle, LanguageClient#serverStatus() returns 0
  if LanguageClient#serverStatus() == 0
    call timer_stop(s:timer)
    unlet s:timer
    let s:lcn = s:frames[0]
  endif
  redraws!
endfunction

function! S_languageclient_neovim() abort
  if !exists('g:LanguageClient_loaded') | return '' | endif
  let l:black_list = ['startify', 'nerdtree', 'fugitiveblame', 'gitcommit']
  if count(l:black_list, &filetype) | return '' | endif
  if LanguageClient#serverStatus() == 1
    if !exists('s:timer')
      let s:timer = timer_start(80, function('s:OnFrame'), {'repeat': -1})
    endif
  endif
  return s:lcn
endfunction

function! S_coc() abort
  if s:is_tmp_file() | return '' | endif
  return get(g:, 'coc_status', '')
endfunction

" https://github.com/liuchengxu/eleline.vim/wiki
function! s:StatusLine() abort
  function! s:def(fn) abort
    return printf('%%#%s#%%{%s()}%%*', a:fn, a:fn)
  endfunction
  let l:bufnr_winnr = s:def('ElelineBufnrWinnr')
  let l:paste = s:def('ElelinePaste')
  let l:curfname = s:def('ElelineCurFname')
  let l:branch = s:def('ElelineGitBranch')
  let l:status = s:def('ElelineGitStatus')
  let l:error = s:def('ElelineError')
  let l:warning = s:def('ElelineWarning')
  let l:tags = '%{S_gutentags()}'
  let l:lcn = '%{S_languageclient_neovim()}'
  let l:coc = '%{S_coc()}'
  let l:common = l:curfname.l:branch.l:status.l:error.l:warning.l:tags.l:lcn.l:coc
  if get(g:, 'eleline_slim', 0)
    return l:bufnr_winnr.l:paste.'%<'.l:common
  endif
  let l:tot = s:def('ElelineBufNr')
  let l:fsize = '%#ElelineFsize# %{ElelineFsize(@%)} %*'
  let l:m_r_f = '%7* %m%r%y %*'
  let l:pos = '%8* '.(s:font?"\ue0a1":'').'%l/%L:%c%V |'
  let l:enc = " %{''.(&fenc!=''?&fenc:&enc).''} | %{(&bomb?\",BOM \":\"\")}"
  let l:ff = '%{&ff} %*'
  let l:pct = '%9* %P %*'
  return l:bufnr_winnr.l:paste.l:tot.'%<'.l:fsize.l:common
        \ .'%='.l:tags.l:m_r_f.l:pos.l:enc.l:ff.l:pct
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

function! s:hi(group, dark, light, ...)
  let [fg, bg] = &bg ==# 'dark' ? a:dark : a:light

  if &bg ==# 'light'
    " Bug of vim. fg -> bg
    let ctermbg = synIDattr(synIDtrans(hlID('StatusLine')), 'fg', 'cterm')
    let guibg = synIDattr(synIDtrans(hlID('StatusLine')), 'fg', 'gui')
    execute printf('hi %s ctermfg=%d guifg=%s ctermbg=%d guibg=%s',
                  \ a:group, fg, s:colors[fg], ctermbg, guibg)
  else
    execute printf('hi %s ctermfg=%d guifg=%s ctermbg=%d guibg=%s',
                  \ a:group, fg, s:colors[fg], bg, s:colors[bg])
  endif
  if a:0 == 1
    execute printf('hi %s cterm=%s gui=%s', a:group, a:1, a:1)
  endif
endfunction

function! s:hi_statusline()
  call s:hi('ElelineBufnrWinnr' , [232 , 178]     , [232     , 178]  )
  call s:hi('ElelineBufNr'      , [178 , s:bg+8]  , [240     , ''] )
  call s:hi('ElelinePaste'      , [232 , 178]     , [232     , 178]    , 'bold')
  call s:hi('ElelineFsize'      , [250  , s:bg+6], [235, ''] )
  call s:hi('ElelineCurFname'   , [171  , s:bg+4], [171, '']   , 'bold' )
  call s:hi('ElelineGitBranch'  , [184  , s:bg+2], [184, '']   , 'bold' )
  call s:hi('ElelineGitStatus'  , [208  , s:bg+2], [184, ''])
  call s:hi('ElelineError'      , [197  , s:bg+2], [197, ''])
  call s:hi('ElelineWarning'    , [214  , s:bg+2], [214, ''])

  call s:hi('User5'           , [208 , s:bg+3], [208, ''] )
  call s:hi('User7'      , [249 , s:bg+3], [237, ''] )
  call s:hi('User8'      , [250 , s:bg+4], [238, ''] )
  call s:hi('User9'      , [251 , s:bg+5], [239, ''] )
endfunction

function! s:InsertStatuslineColor(mode)
  if a:mode == 'i'
    call s:hi('ElelineBufnrWinnr' , [251, s:bg+8] , [251, s:bg+8])
  elseif a:mode == 'r'
    call s:hi('ElelineBufnrWinnr' , [232, 160], [232, 160])
  else
    call s:hi('ElelineBufnrWinnr' , [232, 178], [232, 178])
  endif
endfunction

" Note that the "%!" expression is evaluated in the context of the
" current window and buffer, while %{} items are evaluated in the
" context of the window that the statusline belongs to.
function! s:SetStatusline(...) abort
  call ElelineGitBranch(1)
  let &l:statusline = s:StatusLine()
  " User-defined highlightings shoule be put after colorscheme command.
  call s:hi_statusline()
endfunction

if exists('*timer_start')
  call timer_start(100, function('s:SetStatusline'))
else
  call s:SetStatusline()
endif

augroup eleline
  autocmd!
  autocmd User GitGutter,Startified,LanguageClientStarted call s:SetStatusline()
  " Change colors for insert mode
  autocmd InsertLeave * call s:hi('ElelineBufnrWinnr', [232, 178], [232, 178])
  autocmd InsertEnter,InsertChange * call s:InsertStatuslineColor(v:insertmode)
  autocmd BufWinEnter,ShellCmdPost,BufWritePost * call s:SetStatusline()
  autocmd FileChangedShellPost,ColorScheme * call s:SetStatusline()
  autocmd FileReadPre,ShellCmdPost,FileWritePost * call s:SetStatusline()
augroup END

let &cpoptions = s:save_cpo
unlet s:save_cpo
