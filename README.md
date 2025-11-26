# bufdelete.nvim

Neovim plugin to quickly and easily close multiple buffers.

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
