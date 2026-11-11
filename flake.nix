{
  description = "Lua development environment";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs, ... }:
    let
      forAllSystems =
        f:
        nixpkgs.lib.genAttrs [
          "x86_64-linux"
          "aarch64-linux"
        ] (system: f nixpkgs.legacyPackages.${system});
    in
    {
      # The Neovim plugin, for `programs.neovim.plugins` and the like
      packages = forAllSystems (pkgs: {
        default = pkgs.vimUtils.buildVimPlugin {
          pname = "lonelog-vim";
          version = self.shortRev or self.dirtyShortRev or "dev";
          # Only what Neovim loads, so docs and test changes don't rebuild the plugin
          src = pkgs.lib.fileset.toSource {
            root = ./.;
            fileset = pkgs.lib.fileset.unions [
              ./ftplugin
              ./lua
              ./plugin
              ./queries
              ./tree-sitter-lonelog/src
            ];
          };
          # Compile the parser from the committed generated source (no tree-sitter CLI needed)
          # to parser/lonelog.so, where Neovim looks for it on the runtimepath
          buildPhase = ''
            runHook preBuild
            mkdir -p parser
            $CC -O2 -shared -fPIC -I tree-sitter-lonelog/src \
              tree-sitter-lonelog/src/parser.c -o parser/lonelog.so
            rm -r tree-sitter-lonelog
            runHook postBuild
          '';
        };
      });

      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = with pkgs; [
            (lua5_4.withPackages (
              ps: with ps; [
                luarocks # deps: `luarocks install --tree lua_modules <rock>`
                busted # tests: `busted` runs spec/*_spec.lua
              ]
            ))
            lua-language-server
            stylua # format: `stylua .`
            lua54Packages.luacheck # lint: `luacheck .`
            tree-sitter # grammar: `make` generates, tests and builds parser/lonelog.so
            gcc # compiles the generated parser
          ];
          # Let `require` find rocks installed into the project-local lua_modules tree
          shellHook = ''
            eval "$(luarocks --tree lua_modules path)"
          '';
        };
      });
    };
}
