# bufdelete.nvim

Simple Neovim plugin to quickly and easily close multiple buffers.

https://github.com/user-attachments/assets/76be500b-6577-4f10-9859-3398a2dbe97f

## Installation

```lua
-- lazy.nvim
{
  dir = 'ljsoph/bufdelete.nvim/',
  lazy = false,
},
```

## Usage

Simply toggle the buffer list with `:BufDeleteToggle` and remove the lines containing the buffers you wish to close.

Toggle once more to delete the removed buffers. This has the same effect of calling `:bdelete` on each buffer.
