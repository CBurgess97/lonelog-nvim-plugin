if vim.g.loaded_lonelog then
  return
end
vim.g.loaded_lonelog = true

local lonelog = require("lonelog")
lonelog.setup_filetype()
lonelog.setup_treesitter()
