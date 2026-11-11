# lonelog-vim

Neovim support for [Lonelog](https://lonelog.readthedocs.io) 1.5.0, a notation for logging solo
TTRPG sessions, and for Partylog 1.0.0, its fork for group play. Requires Neovim 0.12+.

## Features

- **Filetype detection.** `*.lonelog.md` files, or any `.md` with `lonelog: true` in its YAML
  front matter, get the compound filetype `markdown.lonelog`, so markdown behaviour is kept.
- **Tree-sitter highlighting** for Lonelog notation in a `markdown.lonelog` buffer:
  - untagged fenced code blocks (the format Lonelog recommends)
  - indented code blocks
  - notation written straight into paragraphs, block quotes and list items
- Fences tagged ` ```lonelog ` are highlighted in any markdown buffer.

The grammar covers core notation (`@`, `?`, `d:`, `->`, `=>`) and tags (`[N:…]`, `[#N:…]`,
`[Clock:… 3/6]`, multi-line tags). It also handles meta notes, tables and generators, dialogue,
excerpts, and analog session and scene markers.

Add-on support:

| Add-on | What's recognised |
| --- | --- |
| Combat | `[COMBAT]`…`[/COMBAT]`, `Rd1` rounds, compact one-line rounds (`Rd1 @ Slash d:17≥12 Hit => [F:Thug|dead]`), `[F:…]` foes |
| Dungeon Crawling | `[R:…]` rooms, `[DUNGEON STATUS]` blocks |
| Resource Tracking | `[Inv:…]`, `[Wealth:…]`, deltas (`HP-2`), counts (`×3`), transitions (`3→1`, `d8→d6`) |
| Wargaming | `Tn1` turns, `[Unit:…]`, `[Force:…]`, `[Scenario:…]`, `[BATTLE]`, `[CAMPAIGN]` |
| Dice Notation | modifiers such as `4d6dl1`, `2d20kh1`, `d6!`, `4dF`, `d%`, `5d10>=7` |
| Cards | draws in a roll: `d: draw=Qs`, `Past=M16r`, `Future=KnCu` |

Any `[UPPERCASE NAME]` block and any `[Type:…]` tag is recognised, so community add-ons that
follow the add-on guidelines work too. Not covered: dice pools in braces (`{4d6, 2d10}`), roll
breakdowns (`[4, 6!, 2]`) and `//` labels.

Partylog shares the same grammar and filetype: name the file `*.lonelog.md` or set
`lonelog: true` in its front matter. On top of the shared notation it adds `!` world events,
attributed rolls (`d(Kael): …`, `d(Mira > Kael): …`), bare `R1` rounds, unspaced dialogue
(`PC(Kael): "…"`) and tags such as `[Party:…]` and `[Faction:…]`.

Highlights use standard captures (`@keyword`, `@type`, `@number`, …), so any colorscheme works. To
style Lonelog on its own, override the language-specific groups, e.g.
`vim.api.nvim_set_hl(0, "@type.lonelog", { … })`.

## Development

Run everything inside `nix develop`, or let direnv load it.

```sh
make                # generate the grammar, run corpus tests, build parser/lonelog.so
make check          # corpus tests, headless Neovim tests and lint; run before committing
make update-corpus  # rewrite expected trees after a grammar change, then review the diff
```

Use `make update-corpus` rather than `tree-sitter test --update` directly: the corpus files need
`|||`-suffixed delimiters, which a bare update strips.

### Try it without installing

From the repository root:

```sh
make parser
nvim --cmd 'set rtp^=.' test/fixtures/session.lonelog.md
```

Useful checks: `:set ft?`, `:InspectTree`, and `:Inspect` on a Lonelog token.

## Caveats

Notation is recognised by shape, so some prose is highlighted as notation:

- `@`, `d:`, `->` and `=>` count anywhere in a line (compact combat rounds need this), so a stray
  ` @ ` or ` => ` in a sentence is highlighted.
- A line that starts with `? `, `! `, a scene ID (`S3 …`) or a round ID (`R2 …`, `Rd1 …`, `Tn1 …`)
  is treated as that kind of line.
- Dice shapes such as `d20` are highlighted wherever they appear.

When notation is written outside fences, markdown parses the text first, so a few things still
behave as markdown:

- A bare `---` line directly under a notation line turns it into a heading.
- `[Tag]: text` at the start of a line is a link reference definition.
- A bare `[text]` loses its link styling in Lonelog buffers; inline links `[text](url)` keep it.
- Consecutive notation lines render as a single paragraph in markdown previews. This is why
  Lonelog recommends fences.
