local M = {}

local config = {}
local default_config = {
  floating = true,
  cursorline = true,
  width = 0.3,
  height = 0.3,
  padding = {
    top = 0,
    left = 0,
    right = 0,
    bottom = 0,
  },
}

function M.setup(opts)
  config = vim.tbl_deep_extend("force", default_config, opts or {})
end

local state = {
  buffers = {},
  current_win = -1,
  current_buf = -1,
  win_info = { buf = -1, win = -1 },
}

---@param name string: Full path of file
---@param cwd string: Current working directory
---@return boolean
local in_cwd = function(name, cwd)
  local prefix = string.sub(name, 1, string.len(cwd))
  return prefix == cwd
end

---@class bufdelete.Buffer
---@field bufnr number: Buffer number
---@field name string: Full path of file
---
---@param bufs bufdelete.Buffer[]
---@return string[]
local to_buffer_lines = function(bufs)
  local buffer_lines = {}

  for _, buf in ipairs(bufs) do
    local len = math.ceil(math.log10(buf.bufnr)) or 1
    if len == 0 then
      len = len + 1
    end
    local padding = 6 - len
    table.insert(buffer_lines, string.format("%d%s%s", buf.bufnr, string.rep(" ", padding), buf.name))
  end

  return buffer_lines
end

local get_open_buffers = function()
  local cwd = vim.fn.getcwd()
  local bufnrs = vim.tbl_filter(function(bufnr)
    if not vim.api.nvim_buf_is_loaded(bufnr) then
      return false
    end

    if vim.fn.buflisted(bufnr) == 0 then
      return false
    end

    return true
  end, vim.api.nvim_list_bufs())

  local buffers = {}
  for _, bufnr in ipairs(bufnrs) do
    local info = vim.fn.getbufinfo(bufnr)[1]

    local item = {
      bufnr = bufnr,
      name = info.name,
    }

    if in_cwd(info.name, cwd) then
      item.name = string.sub(info.name, #cwd + 2)
    end

    table.insert(buffers, item)
  end

  return buffers
end

local delete_buffers = function()
  local new_lines = vim.api.nvim_buf_get_lines(state.win_info.buf, 0, -1, false)

  local to_keep = {}
  for _, line in ipairs(new_lines) do
    local match = line:match("%d+")
    if match ~= nil then
      local bufnr = tonumber(match)
      table.insert(to_keep, tonumber(bufnr))
    end
  end

  -- Create an empty buffer if we are deleting all open buffers so the last one can be unloaded
  local next_buf = next(to_keep)
  if next_buf == nil then
    local new_buf = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = new_buf })
    vim.api.nvim_buf_delete(state.win_info.buf, { unload = true })
    vim.api.nvim_win_set_buf(state.current_win, new_buf)
  end

  for _, buf in ipairs(state.buffers) do
    local found = false
    for _, bufnr in ipairs(to_keep) do
      if bufnr == buf.bufnr then
        found = true
        break
      end
    end

    if not found then
      vim.bo[buf.bufnr].buflisted = false
      vim.api.nvim_buf_delete(buf.bufnr, { unload = true })

      if buf.bufnr == state.current_buf and next_buf ~= nil then
        vim.api.nvim_win_set_buf(state.current_win, next_buf)
      end
    end
  end
end

local function create_window_opts()
  local clamped_width = math.min(1.0, math.max(config.width, 0.10))
  local clamped_height = math.min(1.0, math.max(config.height, 0.10))
  local width
  local height
  local col
  local row
  local anchor = "NW"

  if config.floating then
    width = math.floor(vim.o.columns * clamped_width)
    height = math.floor(vim.o.lines * clamped_height)
    col = math.floor((vim.o.columns - width) / 2)
    row = math.floor((vim.o.lines - height) / 2)
  else
    anchor = "SW"
    width = vim.o.columns
    height = math.floor(vim.o.lines * clamped_height)
    col = 0
    row = vim.o.lines
  end

  return {
    relative = "editor",
    anchor = anchor,
    width = width,
    height = height,
    col = col,
    row = row,
    style = "minimal",
    border = "single",
    title = "Buffers",
    title_pos = "center",
  }
end

local function create_window(buffers)
  if vim.api.nvim_buf_is_valid(state.win_info.buf) then
    vim.bo[state.win_info.buf].buflisted = false
    vim.api.nvim_buf_delete(state.win_info.buf, { force = true })
  end

  local left_pad = string.rep(" ", config.padding.left)
  local right_pad = string.rep(" ", config.padding.left)
  for index = 1, #buffers do
    buffers[index] = string.format("%s%s%s", left_pad, buffers[index], right_pad)
  end

  for _ = 1, config.padding.top do
    table.insert(buffers, 1, "")
  end

  for _ = 1, config.padding.bottom do
    table.insert(buffers, "")
  end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_option_value("buftype", "acwrite", { buf = buf })
  vim.api.nvim_buf_set_name(buf, "scratch")
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, buffers)

  local win_opts = create_window_opts()
  local win = vim.api.nvim_open_win(buf, true, win_opts)

  if config.cursorline then
    vim.api.nvim_set_option_value("cursorline", true, { win = win })
  end

  return { buf = buf, win = win }
end

local setup_autocommands = function(buf, win)
  vim.api.nvim_create_autocmd("BufWriteCmd", {
    buffer = buf,
    callback = function(params)
      -- Set to unmodified so we don't get prompted to save changes
      -- when we exit vim.
      vim.bo[params.buf].modified = false
      delete_buffers()

      if vim.api.nvim_buf_is_valid(params.buf) then
        vim.bo[params.buf].buflisted = false
        vim.api.nvim_buf_delete(params.buf, { force = true })
      end

      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
      end
    end,
  })

  vim.api.nvim_create_autocmd("WinClosed", {
    buffer = buf,
    callback = function(params)
      if vim.api.nvim_buf_is_valid(params.buf) then
        vim.bo[params.buf].buflisted = false
        vim.api.nvim_buf_delete(params.buf, { unload = true, force = true })
      end
    end,
  })

  vim.api.nvim_create_autocmd("BufLeave", {
    buffer = buf,
    callback = function()
      pcall(vim.api.nvim_win_close, state.win_info.win, true)
    end,
  })

  vim.keymap.set("n", "<ESC>", function()
    vim.api.nvim_win_close(win, true)
  end, {
    buffer = buf,
  })

  vim.keymap.set("n", "q", function()
    vim.api.nvim_win_close(win, true)
  end, {
    buffer = buf,
  })
end

M.toggle = function()
  if vim.api.nvim_win_is_valid(state.win_info.win) then
    vim.api.nvim_win_close(state.win_info.win, true)
  else
    state.current_buf = vim.api.nvim_get_current_buf()
    state.current_win = vim.api.nvim_get_current_win()
    state.buffers = get_open_buffers()
    state.win_info = create_window(to_buffer_lines(state.buffers))

    setup_autocommands(state.win_info.buf, state.win_info.win)
  end
end

return M
