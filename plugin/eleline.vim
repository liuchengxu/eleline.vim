"=================================================
" Filename: eleline.vim
" Author: Liu-Cheng Xu
" Fork: Rocky (@yanzhang0219)
" URL: https://github.com/yanzhang0219/eleline.vim
" License: MIT License
" ================================================

" TODO: Adapt for the light themes

scriptencoding utf-8

" Variables {{{

let s:font = get(g:, 'eleline_nerdfont', 0)
let s:is_win = has('win32')
let s:git_branch_cmd = add(s:is_win ? ['cmd', '/c'] : ['bash', '-c'], 'git branch')

if s:font
  let s:head = '▎'
  let s:logo = ' '
  let s:git_branch_symbol = ''
  let s:git_branch_star_substituted = ''
  let s:diff_icons = [' ', '柳', ' ']
  let s:fn_icon = ''
  let s:separator = ''
  let s:mode_icon = {"n": "🅽  ", "V": "🆅  ", "v": "🆅  ", "\<C-v>": "🆅  ", "i": "🅸  ", "R": "🆁  ", "s": "🆂  ", "t": "🆃  ", "c": "🅲  ", "!": "SE "}
else
  let s:head = ''
  let s:logo = 'YZ'
  let s:git_branch_symbol = 'Git:'
  let s:git_branch_star_substituted = 'Git:'
  let s:diff_icons = ['+', '~', '-']
  let s:fn_icon = 'f'
  let s:separator = '|'
  let s:mode_icon = {"n": "N ", "V": "V ", "v": "V ", "\<C-v>": "V ", "i": "I ", "R": "R ", "s": "S ", "t": "T ", "c": "C ", "!": "SE "}
endif

let s:mode_name = {"n": "Normal", "V": "Visual", "v": "Visual", "\<C-v>": "Visual", "i": "Insert", "R": "Replace", "s": "Select", "t": "Term", "c": "Command", "!": "Shell"}

let s:colors = {
      \   32  : '#3a81c3', 37:   '#0AAEB3', 39  : '#51afef',
      \   89  : '#6c3163',
      \   124 : '#af3a03', 140 : '#af87d7', 149 : '#99cc66',
      \   160 : '#d70000', 171 : '#d75fd7', 172 : '#b57614',
      \   178 : '#ffbb7d', 184 : '#ffe920', 197 : '#cc0033',
      \   208 : '#ff8700', 214 : '#ffff66', 232 : '#333300',
      \
      \   235 : '#262626', 236 : '#303030', 237 : '#3a3a3a',
      \   238 : '#444444', 239 : '#4e4e4e', 240 : '#585858',
      \   241 : '#606060', 242 : '#666666', 243 : '#767676',
      \   244 : '#808080', 245 : '#8a8a8a', 246 : '#949494',
      \   247 : '#9e9e9e', 248 : '#a8a8a8', 249 : '#b2b2b2',
      \   250 : '#bcbcbc', 251 : '#c6c6c6', 252 : '#d0d0d0',
      \   253 : '#dadada', 254 : '#e4e4e4', 255 : '#eeeeee',
      \ }

let s:jobs = {}

" }}}

" Functions for each item {{{

function! ElelineHead() abort
  return s:head
endfunction

function! ElelineLogo() abort
  return ' ' . s:logo . ' '
endfunction

function! ElelineMode() abort
  let l:mode = mode()
  " Change color for different mode
  execute 'hi! link ElelineLogo ElelineLogo' . s:mode_name[l:mode]
  execute 'hi! link ElelineMode ElelineMode' . s:mode_name[l:mode]
  return '  ' . s:mode_icon[l:mode]
endfunction

function! ElelineBufnrWinnr() abort
  return '  W:' . winnr() . '  ' . 'B:' . bufnr('%') . ' '
endfunction

function! ElelineTotalBuf() abort
  return '[' . len(filter(range(1, bufnr('$')), 'buflisted(v:val)')) . ']'
endfunction

function! ElelinePaste() abort
  return &paste ? 'PASTE ' : ''
endfunction

function! ElelineDevicon() abort
  let l:icon = ''
  if exists("*WebDevIconsGetFileTypeSymbol")
    let l:icon = substitute(WebDevIconsGetFileTypeSymbol(), "\u00A0", '', '')
  else
    let l:file_name = expand("%:t")
    let l:file_extension = expand("%:e")
    if luaeval("require('nvim-web-devicons').get_icon")(l:file_name,l:file_extension) == v:null
      let l:icon = ' '
    else
      let l:icon = luaeval("require('nvim-web-devicons').get_icon")(l:file_name,l:file_extension)
    endif
  endif
  return '  ' . l:icon
endfunction

function! ElelineCurFname() abort
  return &filetype ==# 'startify' ? ' ' : '  ' . expand('%:p:t') . ' '
endfunction

function! s:IsTmpFile() abort
  return !empty(&buftype)
        \ || index(['startify', 'gitcommit', 'defx', 'vista', 'vista_kind'], &filetype) > -1
        \ || expand('%:p') =~# '^/tmp'
endfunction

" Probe git branch asynchronously
function! ElelineGitBranch(...) abort
  if s:IsTmpFile()
    return ''
  endif
  let reload = get(a:, 1, 0) == 1
  if exists('b:eleline_branch') && !reload
    return b:eleline_branch
  endif
  if !exists('*FugitiveExtractGitDir')
    return ''
  endif
  let dir = exists('b:git_dir') ? b:git_dir : FugitiveExtractGitDir(resolve(expand('%:p')))
  if empty(dir)
    return ''
  endif
  let b:git_dir = dir
  let roots = values(s:jobs)
  let root = fnamemodify(dir, ':h')
  if index(roots, root) >= 0
    return ''
  endif

  if exists('*job_start')
    let job = job_start(s:git_branch_cmd, {'out_io': 'pipe', 'err_io':'null',  'out_cb': function('s:OutHandler')})
    if job_status(job) ==# 'fail'
      return ''
    endif
    let s:cwd = root
    let job_id = ch_info(job_getchannel(job))['id']
    let s:jobs[job_id] = root
  elseif exists('*jobstart')
    let job_id = jobstart(s:git_branch_cmd, {
          \ 'cwd': root,
          \ 'stdout_buffered': v:true,
          \ 'stderr_buffered': v:true,
          \ 'on_exit': function('s:ExitHandler')
          \})
    if job_id == 0 || job_id == -1
      return ''
    endif
    let s:jobs[job_id] = root
  elseif exists('g:loaded_fugitive')
    let l:head = fugitive#head()
    return empty(l:head) ? '' : ' ' . s:git_branch_symbol . ' ' . l:head
  endif

  return ''
endfunction

function! s:OutHandler(channel, message) abort
  if a:message =~# '^* '
    let l:job_id = ch_info(a:channel)['id']
    if !has_key(s:jobs, l:job_id)
      return
    endif
    let l:branch = substitute(a:message, '*', '  ' . s:git_branch_star_substituted, '')
    call s:SetGitBranch(s:cwd, l:branch . ' ')
    call remove(s:jobs, l:job_id)
  endif
endfunction

function! s:ExitHandler(job_id, data, _event) dict abort
  if !has_key(s:jobs, a:job_id) || !has_key(self, 'stdout')
    return
  endif
  if v:dying
    return
  endif
  let l:cur_branch = join(filter(self.stdout, 'v:val =~# "*"'))
  if !empty(l:cur_branch)
    let l:branch = substitute(l:cur_branch, '*', '  ' . s:git_branch_star_substituted, '')
    call s:SetGitBranch(self.cwd, l:branch . ' ')
  else
    let err = join(self.stderr)
    if !empty(err)
      echoerr err
    endif
  endif
  call remove(s:jobs, a:job_id)
endfunction

function! s:SetGitBranch(root, str) abort
  let buf_list = filter(range(1, bufnr('$')), 'bufexists(v:val)')
  let root = s:is_win ? substitute(a:root, '\', '/', 'g') : a:root
  for nr in buf_list
    let path = fnamemodify(bufname(nr), ':p')
    if s:is_win
      let path = substitute(path, '\', '/', 'g')
    endif
    if match(path, root) >= 0
      call setbufvar(nr, 'eleline_branch', a:str)
    endif
  endfor
  redraws!
endfunction

function! ElelineGitStatus() abort
  if exists('b:sy.stats')
    let l:summary = b:sy.stats
  elseif exists('b:gitgutter.summary')
    let l:summary = b:gitgutter.summary
  else
    let l:summary = [0, 0, 0]
  endif
  if max(l:summary) > 0
    return s:diff_icons[0] . l:summary[0] . ' ' . s:diff_icons[1] . l:summary[1] . ' ' . s:diff_icons[2] . l:summary[2]
  elseif !empty(get(b:, 'coc_git_status', ''))
    return ' ' . b:coc_git_status . ' '
  endif
  return ''
endfunction

function! ElelineTag() abort
  return exists("b:gutentags_files") ? gutentags#statusline() . ' ' : ''
endfunction

function! ElelineCoc() abort
  if s:IsTmpFile()
    return ''
  endif
  if get(g:, 'coc_enabled', 0)
    return coc#status() . '  '
  endif
  return ''
endfunction

function! ElelineFunction() abort
  let l:function = ''
  if get(g:, 'coc_enabled', 0) && !empty(get(b:,'coc_current_function',''))
    let l:function = b:coc_current_function
  elseif !empty(get(b:, 'vista_nearest_method_or_function', ''))
    let l:function = '[' . s:fn_icon . '] ' . b:vista_nearest_method_or_function
  elseif has('nvim-0.5') && !s:IsTmpFile() && luaeval('#vim.lsp.buf_get_clients() > 0')
    let l:function = s:fn_icon . ' ' . luaeval("require('lsp-status').status()")
  endif
  return !empty(l:function) ? l:function : ''
endfunction

function! ElelineFileSize(f) abort
  let l:size = getfsize(expand(a:f))
  if l:size == 0 || l:size == -1 || l:size == -2
    return ''
  endif
  if l:size < 1024
    let size = l:size . ' B'
  elseif l:size < 1024 * 1024
    let size = printf('%.1f', l:size/1024.0) . 'K'
  elseif l:size < 1024 * 1024 * 1024
    let size = printf('%.1f', l:size/1024.0/1024.0) . 'M'
  else
    let size = printf('%.1f', l:size/1024.0/1024.0/1024.0) . 'G'
  endif
  return ' ' . size . ' '
endfunction

function! ElelineScrollbar() abort
  let l:scrollbar_chars = [
        \  '▁', '▁', '▂', '▃', '▄', '▅', '▆', '▇', '█'
        \  ]

  let l:current_line = line('.') - 1
  let l:total_lines = line('$') - 1

  if l:current_line == 0
    let l:index = 0
  elseif l:current_line == l:total_lines
    let l:index = -1
  else
    let l:line_no_fraction = floor(l:current_line) / floor(l:total_lines)
    let l:index = float2nr(l:line_no_fraction * len(l:scrollbar_chars))
  endif

  return l:scrollbar_chars[l:index]
endfunction

" }}}

" Colorize {{{

function! s:Extract(group, what, ...) abort
  if a:0 == 1
    return synIDattr(synIDtrans(hlID(a:group)), a:what, a:1)
  else
    return synIDattr(synIDtrans(hlID(a:group)), a:what)
  endif
endfunction

" Set the background color
function! s:SetBg() abort
  if !exists('g:eleline_background')
    let s:normal_bg = s:Extract('Normal', 'bg', 'cterm')
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
endfunction

" TODO: Adapt for the light themes
" @light here is just a placeholder
function! s:Hi(group, dark, light, ...) abort
  let [fg, bg] = a:dark
  execute printf('hi %s ctermfg=%d guifg=%s ctermbg=%d guibg=%s',
        \ a:group, fg, s:colors[fg], bg, s:colors[bg])
  if a:0 == 1
    execute printf('hi %s cterm=%s gui=%s', a:group, a:1, a:1)
  endif
endfunction

" Create highlight groups
function! s:HiStatusline() abort
  " Left section
  call s:Hi('ElelineHead'        , [39  , s:bg+2] , ['' , ''])
  call s:Hi('ElelineLogo'        , [140 , s:bg+2] , ['' , ''])
  call s:Hi('ElelineMode'        , [232 , 140]    , ['' , '']    , 'bold')
  call s:Hi('ElelineBufnrWinnr'  , [232 , 178]    , ['' , ''])
  call s:Hi('ElelineTotalBuf'    , [178 , s:bg+7] , ['' , ''])
  call s:Hi('ElelinePaste'       , [232 , 178]    , ['' , '']    , 'bold')
  call s:Hi('ElelineDevicon'     , [171 , s:bg+4] , ['' , ''])
  call s:Hi('ElelineCurFname'    , [171 , s:bg+4] , ['' , '']    , 'bold')
  call s:Hi('ElelineGitBranch'   , [184 , s:bg+2] , ['' , '']    , 'bold')
  call s:Hi('ElelineGitStatus'   , [208 , s:bg+2] , ['' , ''])
  call s:Hi('ElelineTag'         , [149 , s:bg+2] , ['' , ''])
  call s:Hi('ElelineCoc'         , [39  , s:bg+2] , ['' , ''])
  call s:Hi('ElelineFunction'    , [149 , s:bg+2] , ['' , ''])

  call s:Hi('ElelineLogoNormal'  , [140 , s:bg+2] , ['' , ''])
  call s:Hi('ElelineModeNormal'  , [232 , 140]    , ['' , '']    , 'bold')
  call s:Hi('ElelineLogoInsert'  , [149 , s:bg+2] , ['' , ''])
  call s:Hi('ElelineModeInsert'  , [232 , 149]    , ['' , '']    , 'bold')
  call s:Hi('ElelineLogoVisual'  , [32 , s:bg+2]  , ['' , ''])
  call s:Hi('ElelineModeVisual'  , [232 , 32]     , ['' , '']    , 'bold')
  call s:Hi('ElelineLogoCommand' , [208 , s:bg+2] , ['' , ''])
  call s:Hi('ElelineModeCommand' , [232 , 208]    , ['' , '']    , 'bold')
  call s:Hi('ElelineLogoReplace' , [197 , s:bg+2] , ['' , ''])
  call s:Hi('ElelineModeReplace' , [232 , 197]    , ['' , '']    , 'bold')
  call s:Hi('ElelineLogoSelect'  , [37  , s:bg+2] , ['' , ''])
  call s:Hi('ElelineModeSelect'  , [232 , 37]     , ['' , '']    , 'bold')
  call s:Hi('ElelineLogoTerm'    , [184 , s:bg+2] , ['' , ''])
  call s:Hi('ElelineModeTerm'    , [232 , 184]    , ['' , '']    , 'bold')
  call s:Hi('ElelineLogoShell'   , [171 , s:bg+2] , ['' , ''])
  call s:Hi('ElelineModeShell'   , [232 , 171]    , ['' , '']    , 'bold')

  " Right section
  call s:Hi('ElelineFileType'    , [249 , s:bg+3] , ['' , ''])
  call s:Hi('ElelineFileFmtEnc'  , [250 , s:bg+5] , ['' , ''])
  call s:Hi('ElelineFileSize'    , [251 , s:bg+7] , ['' , ''])
  call s:Hi('ElelinePosPct'      , [252 , s:bg+9] , ['' , ''])
  call s:Hi('ElelineScrollbar'   , [39  , 184]    , ['' , ''])

  " Statusline itseft
  call s:Hi('StatusLine'         , [140 , s:bg+2] , ['' , ''])
endfunction

" }}}

" Set statusline {{{

function! s:DefStatuslineItem(fn) abort
  return printf('%%#%s#%%{%s()}%%*', a:fn, a:fn)
endfunction

function! s:GenerateStatusLine() abort

  " Item candidates for the left section
  let l:head = s:DefStatuslineItem('ElelineHead')
  let l:logo = s:DefStatuslineItem('ElelineLogo')
  let l:mode = s:DefStatuslineItem('ElelineMode')
  let l:bufnr_winnr = s:DefStatuslineItem('ElelineBufnrWinnr')
  let l:paste = s:DefStatuslineItem('ElelinePaste')
  let l:tot = s:DefStatuslineItem('ElelineTotalBuf')
  let l:devicon = s:font ? s:DefStatuslineItem('ElelineDevicon') : ''
  let l:curfname = s:DefStatuslineItem('ElelineCurFname')
  let l:branch = s:DefStatuslineItem('ElelineGitBranch')
  let l:status = s:DefStatuslineItem('ElelineGitStatus')
  let l:tags = s:DefStatuslineItem('ElelineTag')
  let l:coc = s:DefStatuslineItem('ElelineCoc')
  let l:func = s:DefStatuslineItem('ElelineFunction')

  " Item candidates for the right section
  let l:m_r_f = '%#ElelineFileType# %m%r%y %*'
  let l:ff = '%#ElelineFileFmtEnc# %{&ff == "unix" ? " ": &ff} '
  let l:enc = '%{toupper(&fenc != "" ? &fenc : &enc)}%{&bomb ? "[BOM]" : ""} %*'
  let l:fsize = '%#ElelineFileSize#%{ElelineFileSize(@%)}%*'
  let l:pos = '%#ElelinePosPct#  %l/%L:%03c ' . s:separator
  let l:scroll = s:font ? s:DefStatuslineItem('ElelineScrollbar') : ''
  let l:pct = ' %P ' . l:scroll . '%#ElelinePosPct#%*'

  " Assemble the items you want to display
  let l:prefix = l:head . l:logo . l:mode . l:bufnr_winnr . l:paste . l:tot
  let l:common = l:devicon . l:curfname . l:branch . l:status . l:tags . l:coc . l:func
  let l:right = l:m_r_f . l:ff . l:enc . fsize . l:pos . l:pct

  return l:prefix . '%<' . l:common .'%=' . l:right
endfunction

function! s:SetQuickFixStatusline() abort
  let l:bufnr_winnr = s:DefStatuslineItem('ElelineBufnrWinnr')
  let &l:statusline = l:bufnr_winnr . "%{exists('w:quickfix_title')? ' '.w:quickfix_title : ''} %l/%L %p"
endfunction

function! s:SetStatusline(...) abort
  call ElelineGitBranch(1)
  let &l:statusline = s:GenerateStatusLine()
endfunction

function! s:StatusLineInit(...) abort
  call s:SetBg()
  call s:SetStatusline()
  call s:HiStatusline()
endfunction

if exists('*timer_start')
  call timer_start(100, function('s:StatusLineInit'))
else
  call s:StatusLineInit()
endif

augroup eleline
  autocmd!
  autocmd User GitGutter,Startified call s:SetStatusline()
  autocmd BufWinEnter,ShellCmdPost,BufWritePost * call s:SetStatusline()
  autocmd FileChangedShellPost,ColorScheme * call s:SetStatusline()
  autocmd FileReadPre,ShellCmdPost,FileWritePost * call s:SetStatusline()
  autocmd FileType qf call s:SetQuickFixStatusline()
augroup END

" }}}

" vim:set et sw=2 ts=2 fdm=marker
