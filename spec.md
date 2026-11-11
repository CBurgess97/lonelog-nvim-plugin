# LoneLog Nvim Plugin
This is an Nvim plugin which adds support with the lonelog standard for recording solo TTRPG sessions. The current version of Lonelog is 1.5.0. The Lonelog reference can be found here: https://lonelog.readthedocs.io/en/latest/#/

# Phase 1: MVP
- Lonelog file detection. Lonelog files are often .md files, so detect Lonelog files with the following format: {filename}.lonelog.md. Use lonelog: true in the frontmatter as a fallback.
- Text highlighting and Tree-sitter grammar.
- Use a compound filetype, markdown.lonelog, so we keep makedown behavior.
