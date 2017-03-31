scriptencoding utf-8

" =============================================================================
" Filename: eleline.vim
" Author: Liu-Cheng Xu
" URL: https://github.com/liuchengxu/eleline.vim
" License: MIT License
" =============================================================================

if exists('g:loaded_eleline') || v:version < 700
  finish
endif
let g:loaded_eleline = 1

let s:save_cpo = &cpoptions
set cpoptions&vim

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

let s:gui = has('gui_running')

function! S_buf_num()
    let l:circled_num_list = ['① ', '② ', '③ ', '④ ', '⑤ ', '⑥ ', '⑦ ', '⑧ ', '⑨ ', '⑩ ',
                \             '⑪ ', '⑫ ', '⑬ ', '⑭ ', '⑮ ', '⑯ ', '⑰ ', '⑱ ', '⑲ ', '⑳ ']

    return bufnr('%') > 20 ? bufnr('%') : l:circled_num_list[bufnr('%')-1]
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
        if exists('*ALEGetError')
            return !empty(ALEGetError())?ALEGetError():''
        endif
    endif
    return ''
endfunction

function! S_ale_warning()
    if exists('g:loaded_ale')
        if exists('*ALEGetWarning')
            return !empty(ALEGetWarning())?ALEGetWarning():''
        endif
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
    if exists('b:gitgutter_summary')
        let l:summary = get(b:, 'gitgutter_summary')
        if l:summary[0] != 0 || l:summary[1] != 0 || l:summary[2] != 0
            return ' +'.l:summary[0].' ~'.l:summary[1].' -'.l:summary[2].' '
        endif
    endif
    return ''
endfunction

function! S_time()
    return strftime('%Y-%m-%d %H:%M:%S')
endfunction

function! MyStatusLine()

    if s:gui
        let l:buf_num = '%1* [B-%n] ❖ %{winnr()} %*'
    else
        let l:buf_num = '%1* %{S_buf_num()} ❖ %{winnr()} %*'
    endif
    let l:tot = '%2*[TOT:%{S_buf_total_num()}]%*'
    let l:fs = '%3* %{S_file_size(@%)} %*'
    let l:fp = '%4* %{S_full_path()} %*'
    let l:paste = "%#paste#%{&paste?'⎈ paste ':''}%*"
    let l:ale_e = '%#ale_error#%{S_ale_error()}%*'
    let l:ale_w = '%#ale_warning#%{S_ale_warning()}%*'
    let l:git = '%6*%{S_fugitive()}%{S_gitgutter()}%*'
    let l:m_r_f = '%7* %m%r%y %*'
    let l:ff = '%8* %{&ff} |'
    let l:enc = " %{''.(&fenc!=''?&fenc:&enc).''} | %{(&bomb?\",BOM\":\"\")}"
    let l:pos = '%l:%c%V %*'
    let l:time = ' %{S_time()} '
    let l:pct = '%9* %P %*'

    return l:buf_num.l:tot.'%<'.l:fs.l:fp.l:git.l:paste.l:ale_e.l:ale_w.
                \   '%='.l:time.l:m_r_f.l:ff.l:enc.l:pos.l:pct
endfunction
" See the statusline highlightings in s:post_user_config() of core/autoload/core_config.vim

" Note that the "%!" expression is evaluated in the context of the
" current window and buffer, while %{} items are evaluated in the
" context of the window that the statusline belongs to.
set statusline=%!MyStatusLine()

function! S_statusline_hi()
    hi StatusLine   term=bold,reverse ctermfg=140 ctermbg=237 guifg=#af87d7 guibg=#3a3a3a

    hi paste       cterm=bold ctermfg=149 ctermbg=239 gui=bold guifg=#99CC66 guibg=#3a3a3a
    hi ale_error   cterm=None ctermfg=197 ctermbg=237 gui=None guifg=#CC0033 guibg=#3a3a3a
    hi ale_warning cterm=None ctermfg=214 ctermbg=237 gui=None guifg=#FFFF66 guibg=#3a3a3a

    hi User1 cterm=bold ctermfg=232 ctermbg=179 gui=Bold guifg=#333300 guibg=#FFBF48
    hi User2 cterm=None ctermfg=214 ctermbg=243 gui=None guifg=#FFBB7D guibg=#666666
    hi User3 cterm=None ctermfg=251 ctermbg=241 gui=None guifg=#c6c6c6 guibg=#585858
    hi User4 cterm=Bold ctermfg=177 ctermbg=239 gui=Bold guifg=#d75fd7 guibg=#4e4e4e
    hi User5 cterm=None ctermfg=208 ctermbg=238 gui=None guifg=#ff8700 guibg=#3a3a3a
    hi User6 cterm=Bold ctermfg=178 ctermbg=237 gui=Bold guifg=#FFE920 guibg=#444444
    hi User7 cterm=None ctermfg=250 ctermbg=238 gui=None guifg=#bcbcbc guibg=#444444
    hi User8 cterm=None ctermfg=249 ctermbg=239 gui=None guifg=#b2b2b2 guibg=#4e4e4e
    hi User9 cterm=None ctermfg=249 ctermbg=241 gui=None guifg=#b2b2b2 guibg=#606060
endfunction

" User-defined highlightings shoule be put after colorscheme command.
call S_statusline_hi()

augroup STATUSLINE
    autocmd!
    autocmd ColorScheme * call S_statusline_hi()
augroup END

let &cpoptions = s:save_cpo
unlet s:save_cpo
