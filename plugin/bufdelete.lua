vim.api.nvim_create_user_command("BufDeleteToggle", function()
  require("bufdelete").toggle()
end, {})
