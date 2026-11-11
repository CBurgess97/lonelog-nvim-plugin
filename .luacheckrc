std = "lua54"
files["spec"] = { std = "+busted" }
-- Neovim runtime code: LuaJIT with the `vim` global
for _, dir in ipairs({ "lua", "plugin", "ftplugin", "test" }) do
  files[dir] = { std = "luajit", globals = { "vim" } }
end
exclude_files = { "lua_modules", ".direnv", "tree-sitter-lonelog" }
