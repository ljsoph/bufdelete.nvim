local M = {}

M.setup = function()
  -- no-op
end

local state = {
  buffers = {},
  floaty = {
    buf = -1,
    win = -1,
  },
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
---@field lnum number: Current line number in the open buffer
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
      lnum = info.lnum,
    }

    if in_cwd(info.name, cwd) then
      item.name = string.sub(info.name, #cwd + 2)
    end

    table.insert(buffers, item)
  end

  return buffers
end

local remove_buffers = function()
  local new_lines = vim.api.nvim_buf_get_lines(state.floaty.buf, 0, -1, false)

  local to_keep = {}
  for _, line in ipairs(new_lines) do
    local match = line:match("%d+")
    if match ~= nil then
      table.insert(to_keep, tonumber(match))
    end
  end

  -- Create an empty buffer if we are deleting all open buffers so the last one can be unloaded
  local new_buf
  if next(to_keep) == nil then
    new_buf = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_buf_delete(state.floaty.buf, { unload = true })
    vim.api.nvim_set_current_buf(new_buf)
    vim.api.nvim_win_set_buf(0, new_buf)
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
    end
  end
end

local function create_window(buffers, opts)
  opts = opts or {}

  local width = math.floor(vim.o.columns * 0.3)
  local height = math.floor(vim.o.lines * 0.3)
  local col = math.floor((vim.o.columns - width) / 2)
  local row = math.floor((vim.o.lines - height) / 2)

  local buf = nil
  if vim.api.nvim_buf_is_valid(opts.buf) then
    buf = opts.buf
  else
    buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_option_value("buftype", "acwrite", { buf = buf })
    vim.api.nvim_buf_set_name(buf, "scratch")

    vim.api.nvim_create_autocmd("BufWriteCmd", {
      buffer = buf,
      callback = function(params)
        -- Set to unmodified so we don't get prompted to save changes
        -- when we exit vim.
        vim.bo[params.buf].modified = false
        remove_buffers()
        if vim.api.nvim_win_is_valid(state.floaty.win) then
          vim.api.nvim_win_hide(state.floaty.win)
        end
      end,
    })
  end

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, buffers)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    col = col,
    row = row,
    style = "minimal",
    border = "rounded",
    title = "Buffers",
  })

  return { buf = buf, win = win }
end

M.toggle = function()
  if vim.api.nvim_win_is_valid(state.floaty.win) then
    vim.api.nvim_win_hide(state.floaty.win)
  else
    state.buffers = get_open_buffers()
    state.floaty = create_window(to_buffer_lines(state.buffers), { buf = state.floaty.buf })
  end

  vim.api.nvim_create_autocmd("BufLeave", {
    buffer = state.floaty.buf,
    callback = function()
      pcall(vim.api.nvim_win_close, state.floaty.win, true)
    end,
  })
end

return M
