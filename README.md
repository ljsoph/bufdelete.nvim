# bufdelete.nvim

Simple Neovim plugin to quickly and easily close multiple buffers.

https://github.com/user-attachments/assets/0d0e6ad2-8f8f-4526-b001-05c5f89d7215

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

> [!NOTE]
> To apply your changes you must save! Closing the buffer list (with `:q` or `:BufDeleteToggle`) will have no effect.

