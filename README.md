# eleline.vim
An **ele**gant status **line** for vim, extracted from [space-vim](https://github.com/liuchengxu/space-vim).

![screenshot](https://github.com/liuchengxu/eleline.vim/blob/screenshots/screenshot.png?raw=true)

Supported plugins:

- [vim-gitgutter](https://github.com/airblade/vim-gitgutter)
- [vim-fugitive](https://github.com/tpope/vim-fugitive)
- [ale](https://github.com/w0rp/ale)

    You need to add [two functions](https://github.com/liuchengxu/space-vim/blob/master/layers/%2Bcheckers/syntax-checking/config.vim#L23-L50) `ALEGetError()` and `ALEGetWarning()` to support ale.

## Installation

This plugin can be installed with a varity of plugin managers, e.g., [vim-plug](https://github.com/junegunn/vim-plug):


```vim
Plug 'liuchengxu/eleline.vim'
```

It's encouraged to fork [eleline.vim](https://github.com/liuchengxu/eleline.vim) to make your own custom vim statusline.

