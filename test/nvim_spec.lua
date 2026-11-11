-- Headless checks for filetype detection and Lonelog injections.
-- Run with `make test-nvim` (needs parser/lonelog.so, built by `make parser`).

vim.o.swapfile = false

local failures = 0

local function check(name, ok, detail)
  if ok then
    io.write("ok   " .. name .. "\n")
  else
    failures = failures + 1
    io.write("FAIL " .. name .. (detail and (": " .. detail) or "") .. "\n")
  end
end

local function open(path)
  vim.cmd("edit! " .. path)
  local buf = vim.api.nvim_get_current_buf()
  vim.treesitter.get_parser(buf):parse(true)
  return buf
end

--- Lonelog capture names at the first match of `needle` (searched from line 1).
local function lonelog_captures(buf, needle)
  for row, line in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
    local col = line:find(needle, 1, true)
    if col then
      local names = {}
      for _, c in ipairs(vim.treesitter.get_captures_at_pos(buf, row - 1, col - 1)) do
        if c.lang == "lonelog" then
          table.insert(names, c.capture)
        end
      end
      return names
    end
  end
  error("needle not found: " .. needle)
end

local function has(names, capture)
  return vim.list_contains(names, capture), vim.inspect(names)
end

-- Filetype detection
local buf = open("test/fixtures/session.lonelog.md")
check("*.lonelog.md is markdown.lonelog", vim.bo[buf].filetype == "markdown.lonelog")
check("lonelog parser loads", vim.treesitter.language.add("lonelog") == true)

local fm = open("test/fixtures/frontmatter.md")
check("front matter flag is markdown.lonelog", vim.bo[fm].filetype == "markdown.lonelog")

local plain = open("test/fixtures/plain.md")
check("plain .md stays markdown", vim.bo[plain].filetype == "markdown")

-- Injections in a Lonelog buffer
buf = open("test/fixtures/session.lonelog.md")
check("untagged fence", has(lonelog_captures(buf, "@ Sneak"), "keyword"))
check("dice in fence", has(lonelog_captures(buf, "d6=5"), "number"))
check("paragraph", has(lonelog_captures(buf, "? Is anyone"), "keyword"))
check("indented code block", has(lonelog_captures(buf, "@ Search"), "keyword"))
check("indented code block tag", has(lonelog_captures(buf, "[N:Viktor"), "type"))
check("block quote", has(lonelog_captures(buf, "@ Quoted"), "keyword"))
check("block quote progress", has(lonelog_captures(buf, "5/12"), "number"))
check("list item", has(lonelog_captures(buf, "@ Listed"), "keyword"))
check("tagged fence", has(lonelog_captures(buf, "(note: tagged"), "comment"))
check("other languages untouched", #lonelog_captures(buf, "@ not lonelog") == 0)
check("headings untouched", #lonelog_captures(buf, "S1 *School") == 0)
check("front matter untouched", #lonelog_captures(buf, "title:") == 0)

-- markdown ftplugin features that depend on the buffer's language still being markdown
local ok, err = pcall(require("vim.treesitter._headings").jump, { count = 1 })
check("]] heading navigation works", ok, tostring(err))

--- Whether markdown_inline's `lonelog.tag` capture covers the first match of `needle`.
local function has_tag_reset(b, needle)
  for row, line in ipairs(vim.api.nvim_buf_get_lines(b, 0, -1, false)) do
    local col = line:find(needle, 1, true)
    if col then
      for _, c in ipairs(vim.treesitter.get_captures_at_pos(b, row - 1, col - 1)) do
        if c.lang == "markdown_inline" and c.capture == "lonelog.tag" then
          return true
        end
      end
      return false
    end
  end
  error("needle not found: " .. needle)
end

-- Tags in paragraphs are shielded from markdown link styling; real links are not
check("tag in paragraph gets link-style reset", has_tag_reset(buf, "[Clock"))
check("real link is left alone", not has_tag_reset(buf, "[a real link]"))
check("non-tag brackets are left alone", not has_tag_reset(buf, "[whispers]"))
check(
  "reset group is nocombine",
  vim.api.nvim_get_hl(0, { name = "@lonelog.tag" }).nocombine == true
)
vim.cmd("colorscheme default")
check(
  "reset group survives colorscheme change",
  vim.api.nvim_get_hl(0, { name = "@lonelog.tag" }).nocombine == true
)

-- Tag brackets in paragraphs survive markdown's link conceal
vim.o.columns, vim.o.lines = 60, 10
vim.wo.conceallevel = 2
vim.fn.search("Clock")
vim.cmd("normal! zt2j") -- conceal never applies on the cursor line
vim.cmd("redraw!")
local screen = {}
for col = 1, 25 do
  screen[#screen + 1] = vim.fn.screenstring(1, col)
end
screen = table.concat(screen)
check("tag brackets not concealed", screen:find("[Clock:", 1, true) ~= nil, screen)
vim.wo.conceallevel = 0

-- Plain markdown only gets tagged fences
plain = open("test/fixtures/plain.md")
check("plain: tag-shaped link keeps link style", not has_tag_reset(plain, "[N:Plain"))
check("plain: untagged fence", #lonelog_captures(plain, "@ Untagged") == 0)
check("plain: paragraph", #lonelog_captures(plain, "@ So does") == 0)
check("plain: tagged fence", has(lonelog_captures(plain, "@ Tagged"), "keyword"))

-- Switching a markdown buffer to Lonelog re-parses it
plain = open("test/fixtures/plain.md")
vim.bo[plain].filetype = "markdown.lonelog"
vim.treesitter.get_parser(plain):parse(true)
check("ft switch re-parses", has(lonelog_captures(plain, "@ So does"), "keyword"))

io.write(failures == 0 and "all passed\n" or (failures .. " failed\n"))
vim.cmd(failures == 0 and "qall!" or "cquit!")
