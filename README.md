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

Open the current buffer list with `:BufDeleteToggle` and remove the lines containing the buffers you wish to close. 

Once saved, this will have the same effect of calling `:bdelete` on each buffer removed from the list.

> [!WARNING]
> To apply your changes you must save! Closing the buffer list (with `:q` or `:BufDeleteToggle`) will have no effect.

