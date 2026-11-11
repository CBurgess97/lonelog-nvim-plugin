-- Runs after ftplugin/markdown.lua for the compound `markdown.lonelog` filetype, which has
-- already started treesitter. If the buffer was markdown before (e.g. `:set ft=markdown.lonelog`),
-- its cached parse has no Lonelog injections, so force a re-parse.
local parser = vim.treesitter.get_parser(0, nil, { error = false })
if parser then
  parser:invalidate(true)
end
