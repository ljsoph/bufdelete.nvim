# bufdelete.nvim

Simple Neovim plugin to quickly and easily close multiple buffers.

https://github.com/user-attachments/assets/0d0e6ad2-8f8f-4526-b001-05c5f89d7215

## Installation

```lua
-- lazy.nvim
{
  dir = 'ljsoph/bufdelete.nvim/',
  opts = {} -- see the configuration section for defaults and available configs
  lazy = false,
},
```

## Usage

Open the current buffer list with `:BufDeleteToggle` and remove the lines containing the buffers you wish to close. 

Once saved, this will have the same effect of calling `:bdelete` on each buffer removed from the list.

> [!NOTE]
> To apply your changes you must save! Closing the buffer list (with `:q` or `:BufDeleteToggle`) will have no effect.

## Configuration

**Default Settings**
```lua
local default_config = {
  -- Display the window as a floating window (centered). If set to false 
  floating = true,
  -- Display the CursorLine in opened window
  cursorline = true,
  -- Width of the window as a percentage of the total number of columns (0.0..=1.0)
  -- This value is ignored if `floating` is set to false.
  width = 0.3,
  -- Height of the window as a percentage of the total number of rows (0.0..=1.0)
  height = 0.3,
  padding = {
    top = 0,
    left = 0,
    right = 0,
    bottom = 0,
  },
}
```
