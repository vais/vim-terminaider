# Terminaider

A Vim plugin that provides a persistent terminal interface for the [aider](https://github.com/paul-gauthier/aider) command-line tool.

## Features

- Persistent terminal window for aider sessions
- Commands to add/remove files to/from the chat
- Automatic folding of conversation segments
- Navigation between conversation segments
- Toggle repo map functionality
- Custom filetype for ftplugin customization

## Installation

Same as any other Vim plugin

## Requirements

- Vim 8.1+ with terminal support
- [aider](https://github.com/paul-gauthier/aider) installed and available in your PATH

## Commands

- `:Terminaider [args]` - Opens a terminal window running aider with the specified arguments
- `:TerminaiderHide` - Hides the aider terminal window
- `:TerminaiderAdd` - Adds the current buffer's file to aider
- `:TerminaiderAddReadOnly` - Adds the current buffer's file to aider as read-only
- `:TerminaiderDrop` - Removes the current buffer's file from aider
- `:TerminaiderExit` - Exits aider after confirmation
- `:TerminaiderToggleRepoMap` - Toggles AIDER_MAP_TOKENS environment variable

## Configuration

```vim
" Set the width of the terminal window (default: 80)
let g:terminaider_width = 100
```

## Key Mappings

Terminaider doesn't create any key mappings by default, but here are some examples you can add to your vimrc:

```vim
" Open/show aider terminal
nmap <silent> <Leader>to :Terminaider --watch-files<CR>

" Hide aider terminal
nmap <silent> <Leader>tq :TerminaiderHide<CR>

" Add current file to aider
nmap <silent> <Leader>ta :TerminaiderAdd<CR>

" Add current file to aider as read-only
nmap <silent> <Leader>tr :TerminaiderAddReadOnly<CR>

" Drop current file from aider
nmap <silent> <Leader>td :TerminaiderDrop<CR>

" Exit aider
nmap <silent> <Leader>tx :TerminaiderExit<CR>

" Toggle repo map
nmap <silent> <Leader>tm :TerminaiderToggleRepoMap<CR>
```

## Terminal Navigation

When in normal mode in the terminal buffer:

- `<C-n>` - Move to the next conversation segment
- `<C-p>` - Move to the previous conversation segment
- `zm` - collapse all conversation segments (folds)
- `zr` - expand all conversation segments (folds)
- `za` - toggle current fold, etc... (all vim folding commands apply to aider conversation segments)

## Custom Filetype

Terminaider sets a custom filetype `terminaider` for the terminal buffer, allowing for ftplugin customization by creating files like:
- `ftplugin/terminaider.vim`
- `after/ftplugin/terminaider.vim`
- `syntax/terminaider.vim`

## License

MIT
