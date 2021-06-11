# eleline.vim

Another **ele**gant status**line** for vim, extracted from [space-vim](https://github.com/liuchengxu/space-vim).

Currently supported plugins:

- [ale](https://github.com/w0rp/ale)
- [coc.nvim](https://github.com/neoclide/coc.nvim)
- [vista.vim](https://github.com/liuchengxu/vista.vim)
- [vim-fugitive](https://github.com/tpope/vim-fugitive)
- [vim-signify](https://github.com/mhinz/vim-signify)
- [vim-gitgutter](https://github.com/airblade/vim-gitgutter)
- [vim-gutentags](https://github.com/ludovicchabant/vim-gutentags)
- [LanguageClient-neovim](https://github.com/autozimu/LanguageClient-neovim)
- [lsp-status.nvim](https://github.com/nvim-lua/lsp-status.nvim)

If you're using newer vim or neovim, i.e., async API is available, eleline will probe the git branch info asynchronously instead of depending on vim-fugitive, making your vim never slower due to the statusline.

## Installation

This plugin can be installed with a variety of plugin managers, e.g., [vim-plug](https://github.com/junegunn/vim-plug):

```vim
Plug 'liuchengxu/eleline.vim'
" Optional. If you use vim-fugitive and want a callback from it to update eleline.
" autocmd User FugitiveChanged if exists("b:eleline_branch") | unlet b:eleline_branch | endif
```

Don't forget to `set laststatus=2` to always display statusline.

## Usage

It's encouraged to fork [eleline.vim](https://github.com/liuchengxu/eleline.vim) to make your own custom vim statusline.

## Customization

- Ordinary font by default

  ![screenshot](https://github.com/liuchengxu/eleline.vim/blob/screenshots/screenshot.png?raw=true)

- Powerline font

  If the powerline font is available, i.e., `let g:airline_powerline_fonts = 1` or `let g:eleline_powerline_fonts = 1`:

  ![screenshot](https://raw.githubusercontent.com/liuchengxu/img/master/eleline.vim/eleline-powerline-font.png)

- Keep it simpler

  Only show the buffer number, window number, filename and info from the plugins via `let g:eleline_slim = 1`:

  ![screenshot](https://raw.githubusercontent.com/liuchengxu/img/master/eleline.vim/eleline_slim.png)

  See `:h CTRL-G` when you need more info.

## License

[MIT](LICENSE)
