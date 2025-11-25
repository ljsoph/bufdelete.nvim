local M = {
  buffers = {},
}

local function create_floating_window(buffers, opts)
  opts = opts or {}

  local width = opts.width or math.floor(vim.o.columns * 0.25)
  local height = opts.height or math.floor(vim.o.lines * 0.25)

  local col = math.floor((vim.o.columns - width) / 2)
  local row = math.floor((vim.o.lines - height) / 2)

  local buf = vim.api.nvim_create_buf(false, true) -- No file, scratch buffer
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, buffers)
  vim.api.nvim_set_option_value("buftype", nil, { buf = buf })

  local win_config = {
    relative = "editor",
    width = width,
    height = height,
    col = col,
    row = row,
    style = "minimal",
    border = "rounded",
    title = "Buffers",
  }

  local win = vim.api.nvim_open_win(buf, true, win_config)

  return { buf = buf, win = win }
end

M.setup = function()
  -- no-op
end

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
---@param buf bufdelete.Buffer
---@return string
local to_line = function(buf)
  local len = math.ceil(math.log10(buf.bufnr)) or 1
  if len == 0 then
    len = len + 1
  end
  local padding = 6 - len
  return string.format("%d%s%s", buf.bufnr, string.rep(" ", padding), buf.name)
end

local open_buffers = function()
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

    table.insert(buffers, to_line(item))
    table.insert(M.buffers, item)
  end

  return buffers
end

local buffers = open_buffers()
local window = create_floating_window(buffers)

vim.api.nvim_create_autocmd({ "BufLeave" }, {
  callback = function()
    local new_lines = vim.api.nvim_buf_get_lines(window.buf, 0, -1, false)

    local to_keep = {}
    for _, line in ipairs(new_lines) do
      local match = line:match("%d+")
      if match ~= nil then
        table.insert(to_keep, tonumber(match))
      end
    end

    for _, buf in ipairs(M.buffers) do
      local found = false
      for i, bufnr in ipairs(to_keep) do
        if bufnr == buf.bufnr then
          found = true
          table.remove(to_keep, i)
          break
        end
      end

      if not found then
        print(string.format("removing %d | %s", buf.bufnr, buf.name))
        vim.api.nvim_set_option_value("buflisted", false, { buf = buf.bufnr })
        vim.api.nvim_buf_delete(buf.bufnr, { unload = true })
      end
    end
  end,
  buffer = window.buf,
})

return M
