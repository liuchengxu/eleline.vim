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

function! eleline#LanguageClientNeovim() abort
  let l:black_list = ['startify', 'nerdtree', 'fugitiveblame', 'gitcommit']
  if count(l:black_list, &filetype)
    return ''
  endif
  if LanguageClient#serverStatus() == 1
    if !exists('s:timer')
      let s:timer = timer_start(80, function('s:OnFrame'), {'repeat': -1})
    endif
  endif
  return s:lcn
endfunction
