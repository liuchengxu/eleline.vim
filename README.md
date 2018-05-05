# eleline.vim

A tiny **ele**gant status**line** for vim, extracted from [space-vim](https://github.com/liuchengxu/space-vim).

- Ordinary font

  ![screenshot](https://github.com/liuchengxu/eleline.vim/blob/screenshots/screenshot.png?raw=true)

- Powerline font

  If the powerline font is available, i.e., `let g:airline_powerline_fonts = 1` or `let g:eleline_powerline_fonts = 1`:

  ![screenshot](https://raw.githubusercontent.com/liuchengxu/img/master/eleline.vim/eleline-powerline-font.png)

Don't forget to `set laststatus=2` to always display statusline in vim.

Supported plugins:

- [vim-gitgutter](https://github.com/airblade/vim-gitgutter)
- [vim-fugitive](https://github.com/tpope/vim-fugitive)
- [ale](https://github.com/w0rp/ale)
- [vim-gutentags](https://github.com/ludovicchabant/vim-gutentags)

## Installation

This plugin can be installed with a varity of plugin managers, e.g., [vim-plug](https://github.com/junegunn/vim-plug):

```vim
Plug 'liuchengxu/eleline.vim'
```

It's encouraged to fork [eleline.vim](https://github.com/liuchengxu/eleline.vim) to make your own custom vim statusline.
