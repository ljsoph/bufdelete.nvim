local api = vim.api

local M = {}

M.setup = function()
  -- no-op
end

local in_cwd = function(name, cwd)
  local prefix = string.sub(name, 1, string.len(cwd))
  return prefix == cwd
end

local open_buffers = function()
  local cwd = vim.fn.getcwd()
  local buffer_nums = vim.tbl_filter(function(bufnr)
    if not api.nvim_buf_is_loaded(bufnr) then
      return false
    end

    if vim.fn.buflisted(bufnr) == 0 then
      return false
    end

    return true
  end, api.nvim_list_bufs())

  local buffers = {}
  for _, buffer_num in ipairs(buffer_nums) do
    local info = vim.fn.getbufinfo(buffer_num)[1]

    local item = {
      buffer_num = buffer_num,
      name = info.name,
      line_num = info.lnum,
    }

    if in_cwd(info.name, cwd) then
      item.name = string.sub(info.name, #cwd + 2)
    end

    table.insert(buffers, item)
  end

  return buffers
end

local buffers = open_buffers()
for _, buffer in ipairs(buffers) do
  print(buffer.name)
end

return M
