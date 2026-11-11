local M = {}

M.filetype = "markdown.lonelog"

-- How far into a file to look for the end of its YAML front matter.
local FRONTMATTER_MAX_LINES = 50

--- Whether the buffer's YAML front matter contains `lonelog: true`.
---@param bufnr integer
---@return boolean
function M.has_frontmatter_flag(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, FRONTMATTER_MAX_LINES, false)
  if lines[1] ~= "---" then
    return false
  end
  for i = 2, #lines do
    local line = lines[i]:gsub("%s+#.*$", "")
    if line == "---" or line == "..." then
      return false
    end
    if line:match("^lonelog:%s*true%s*$") then
      return true
    end
  end
  return false
end

--- Whether a buffer is a Lonelog buffer (its filetype includes `lonelog`).
---@param bufnr integer
---@return boolean
function M.is_lonelog_buffer(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return false
  end
  return vim.list_contains(vim.split(vim.bo[bufnr].filetype, ".", { plain = true }), "lonelog")
end

function M.setup_filetype()
  vim.filetype.add({
    pattern = {
      [".*%.lonelog%.md"] = { M.filetype, { priority = 10 } },
      -- Returning nil falls through to the normal `md` -> markdown detection.
      [".*%.md"] = function(_, bufnr)
        if M.has_frontmatter_flag(bufnr) then
          return M.filetype
        end
      end,
    },
  })
end

function M.setup_treesitter()
  -- Gates the markdown injections in queries/markdown/injections.scm to Lonelog buffers, so
  -- plain markdown files are unaffected. Query sources are buffer numbers for buffer parsers.
  vim.treesitter.query.add_predicate("lonelog-buffer?", function(_, _, source)
    return type(source) == "number" and M.is_lonelog_buffer(source)
  end, { force = true })
end

function M.setup_highlights()
  local function define()
    -- No style of its own: `nocombine` just blocks the markdown link attributes underneath.
    -- See queries/markdown_inline/highlights.scm.
    vim.api.nvim_set_hl(0, "@lonelog.tag", { nocombine = true, default = true })
  end
  define()
  -- Colorschemes clear highlights when they load.
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("lonelog_highlights", { clear = true }),
    callback = define,
  })
end

return M
