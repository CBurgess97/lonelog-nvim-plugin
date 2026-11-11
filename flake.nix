{
  description = "Lua development environment";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { nixpkgs, ... }:
    let
      forAllSystems =
        f:
        nixpkgs.lib.genAttrs [
          "x86_64-linux"
          "aarch64-linux"
        ] (system: f nixpkgs.legacyPackages.${system});
    in
    {
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
          ];
          # Let `require` find rocks installed into the project-local lua_modules tree
          shellHook = ''
            eval "$(luarocks --tree lua_modules path)"
          '';
        };
      });
    };
}
