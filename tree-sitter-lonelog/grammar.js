/**
 * Tree-sitter grammar for Lonelog 1.5.0 notation (https://lonelog.readthedocs.io), including the
 * Combat, Dungeon Crawling, Resource Tracking, Wargaming, Dice Notation and Cards add-ons.
 *
 * Line-oriented and forgiving: text that isn't recognised notation produces no nodes, so prose
 * never yields errors. A line is an optional line-start construct (`?`, `tbl:`, `S1`, `Rd1`, ...)
 * followed by segments. Segments (`@`, `d:`, `->`, `=>`) may start anywhere in a line, which is
 * what the Combat add-on's compact rounds need (`Rd1 @ Slash d:17≥12 Hit => [F:Thug|dead]`); each
 * runs until the next segment marker or the end of the line.
 *
 * Lexical precedence (higher wins regardless of match length):
 *   4  line-start and segment markers
 *   3  inline constructs that open with punctuation ([N:, [COMBAT], (note:, strings)
 *   2  values: dice, cards, comparisons, tag deltas
 *   0  plain words / numbers / punctuation
 */

/* eslint-disable no-undef */

const PREC_MARKER = 4;
const PREC_INLINE = 3;
const PREC_VALUE = 2;

const marker = (text) => alias(token(prec(PREC_MARKER, text)), text);

// Dice Notation add-on. A compare point: `>=5`, `<3`, `=6`, `!=3`.
const CMP = '(>=|<=|!=|<|>|=)\\d+';
const DICE_MODIFIER = [
  `!!?p?(${CMP})?`, // exploding, compounding, penetrating
  'k[hl]?\\d+', // keep
  'd[hl]?\\d+', // drop
  `ro?(${CMP})?`, // re-roll
  `uo?(${CMP})?`, // unique
  'min\\d+',
  'max\\d+',
  `c[sf](${CMP})?`, // critical success / failure
  's[ad]?', // sort
  `${CMP}(f${CMP})?`, // success (and failure) counting; also the `=5` result
].join('|');
const DICE = new RegExp(`\\d*d(\\d+|%|F(\\.\\d+)?)(${DICE_MODIFIER})*([+-]\\d+)?(=\\d+)?`);

// Cards add-on, as drawn in a roll: `=Qs`, `=10d`, `=Jkr`, `=M16r`, `=KnCu`, `=5Swr`.
const CARD = /=((R|B)?Jkr|M\d+r?|(A|[2-9]|10|J|Q|K|Pg|Kn)(h|d|c|s|Cu|Wa|Sw|Pe)r?)/;

module.exports = grammar({
  name: 'lonelog',

  // Newlines are significant (lines are the unit of notation), so only horizontal space is extra.
  extras: (_) => [/[ \t]/],

  rules: {
    source_file: ($) => seq(optional($._line), repeat(seq($._newline, optional($._line)))),

    _newline: (_) => /\r?\n/,

    _line: ($) => choice(seq($._line_start, repeat($._segment)), repeat1($._segment)),

    // ---------------------------------------------------------------- line-start constructs

    _line_start: ($) =>
      choice(
        $.question,
        $.table,
        $.generator,
        $.table_entry,
        $.dialogue,
        $.scene,
        $.round,
        $.header_field,
        $.session_header,
        $.block_marker,
        $.excerpt_delimiter,
        $.aside,
      ),

    // §3.1 `? Is anyone inside?`
    question: ($) => prec.right(seq(field('marker', marker('?')), repeat($._plain))),

    // §4.3 `tbl: d100=42 -> "A broken sword"`, `gen: NPC -> Merchant`
    table: ($) => prec.right(seq(field('marker', marker('tbl:')), repeat($._plain))),
    generator: ($) => prec.right(seq(field('marker', marker('gen:')), repeat($._plain))),

    // §4.3.1 inline table rows: `1-2: Nothing — eerie silence`
    table_entry: ($) =>
      prec.right(
        seq(
          field('key', alias(token(prec(PREC_MARKER, /\d+(-\d+)?:/)), $.entry_key)),
          repeat($._plain),
        ),
      ),

    // §4.4 `N (Guard): "Who's there?"`, `PC: "Stay calm"`
    dialogue: ($) => prec.right(seq(field('speaker', $.speaker), repeat($._plain))),
    speaker: (_) => token(prec(PREC_MARKER, /(PC|N)( ?\([^)\n]*\))?:/)),

    // §5.3 analog scene markers: `S1`, `S5a`, `S7.1`, `T1-S2`, `T1+T2-S5`
    scene: ($) => prec.right(seq(field('id', $.scene_id), repeat($._plain))),
    scene_id: (_) => token(prec(PREC_MARKER, /(T\d+(\+T\d+)*-)?S\d+([a-z]|\.\d+)?/)),

    // Combat rounds and Wargaming turns: `Rd1`, `Tn3 Shoot:`
    round: ($) => prec.right(seq(field('id', $.round_id), repeat($._plain))),
    round_id: (_) => token(prec(PREC_MARKER, /(Rd|Tn)\d+/)),

    // §5.2.2 analog header fields: `[Date]  2025-09-03`
    header_field: ($) =>
      prec.right(
        seq(
          field('name', alias(token(prec(PREC_MARKER, /\[[A-Z][a-z]+\]/)), $.field_name)),
          repeat($._plain),
        ),
      ),

    // §5.2.2 `=== Session 1 ===`
    session_header: (_) => token(prec(PREC_MARKER, /===[^\n]*===/)),

    // Analog add-on blocks: `--- COMBAT ---`, `--- END COMBAT ---`
    block_marker: (_) => token(prec(PREC_MARKER, /---[ \t]+[^\n]*[ \t]---/)),

    // §4.4 narrative excerpt fences `\---` ... `---\`
    excerpt_delimiter: (_) => token(prec(PREC_MARKER, choice('\\---', '---\\'))),

    // §4.5 / §5.3 a line opening with a bare aside: `(Memory triggered by the photograph)`.
    // Mid-line `(d6=4)` roll references stay plain text.
    aside: ($) => seq(alias(token(prec(PREC_MARKER, /\([^)\n]*\)/)), $.meta_note)),

    // ---------------------------------------------------------------- segments

    _segment: ($) => choice($.action, $.roll, $.outcome, $.consequence, $._plain),

    // §3.1 `@ Pick the lock`, `@(Jonah) Keeps watch`
    action: ($) =>
      prec.right(
        seq(field('marker', marker('@')), optional(field('actor', $.actor)), repeat($._plain)),
      ),
    actor: (_) => token.immediate(/\([^)\n]+\)/),

    // §3.2.1 `d: Stealth d6=5 vs TN 4`; Cards add-on `d: draw=Qs`
    roll: ($) =>
      prec.right(seq(field('marker', marker('d:')), repeat(choice($._plain, $.card)))),
    card: (_) => token(prec(PREC_VALUE, CARD)),

    // §3.2.2 `-> Success`, `-> Yes, but... (d6=4)`
    outcome: ($) => prec.right(seq(field('arrow', marker('->')), repeat($._plain))),

    // §3.3 `=> The door creaks open`
    consequence: ($) => prec.right(seq(field('marker', marker('=>')), repeat($._plain))),

    // ---------------------------------------------------------------- inline elements

    _plain: ($) =>
      choice(
        $.tag,
        $.block_tag,
        $.meta_note,
        $.string,
        $.dice,
        $.comparison,
        $._number,
        $._word,
        $._punctuation,
      ),

    // §4.1 / §4.2 and add-on tags: `[N:Jonah|friendly]`, `[#N:Jonah]`, `[Clock:Ritual 5/12]`,
    // `[F:Goblins×4|HP 3 each|Close]`, `[Inv:Torch|3→1]`, `[PC:Kael|Supply d8→d6]`.
    tag: ($) =>
      seq(
        field('open', $.tag_open),
        optional(field('name', $.tag_name)),
        repeat(seq($._tag_break, optional($.tag_attribute))),
        choice(']', $._tag_close_line),
      ),
    tag_open: (_) => token(prec(PREC_INLINE, /\[#?[A-Z][A-Za-z]*:/)),
    tag_name: ($) => repeat1($._tag_piece),
    tag_attribute: ($) =>
      choice(seq(field('key', $.tag_key), repeat($._tag_piece)), repeat1($._tag_piece)),
    // `trait:`, `Zone:`, `Gear:`; only lexed at the start of an attribute.
    tag_key: (_) => token(prec(PREC_VALUE, /[A-Za-z]+:/)),

    _tag_break: ($) => choice(alias('|', $.tag_separator), $._tag_continuation),
    // A multi-line tag continues only onto an indented line or a line starting with `]` (§4.1.8),
    // so an unclosed `[N:...` can't swallow the lines after it.
    _tag_continuation: (_) => token(prec(PREC_INLINE, /\r?\n[ \t]+/)),
    _tag_close_line: (_) => token(prec(PREC_INLINE, /\r?\n\]/)),

    _tag_piece: ($) =>
      choice(
        $.progress,
        $.dice,
        $.delta,
        $.multiplier,
        $.transition,
        $._tag_word,
        $._tag_number,
        $._tag_punctuation,
      ),
    progress: (_) => token(prec(PREC_VALUE, /\d+\/\d+/)), // `5/12`
    delta: (_) => token(prec(PREC_VALUE, /[+-]\d+/)), // `HP-2`, `Gold+15`
    multiplier: (_) => token(prec(PREC_VALUE, /×\d+/)), // `Goblins×4`
    transition: (_) => token(prec(PREC_VALUE, choice('→', '->'))), // `3→1`, `rusty→repaired`
    _tag_word: (_) => /[^|\]\s\d+\-×→]+/,
    _tag_number: (_) => /\d+/,
    _tag_punctuation: (_) => /[+\-×]/,

    // Add-on structural blocks: `[COMBAT]`, `[/COMBAT]`, `[DUNGEON STATUS]`
    block_tag: (_) => token(prec(PREC_INLINE, /\[\/?[A-Z][A-Z ]+[A-Z]\]/)),

    // §4.5 `(note: testing a house rule)` anywhere in a line.
    meta_note: (_) => token(prec(PREC_INLINE, /\([a-z][a-z ]*:[^)\n]*\)/)),

    string: (_) => token(prec(PREC_INLINE, choice(/"[^"\n]*"/, /“[^”\n]*”/))),

    // `d6`, `2d6=8`, `d20+5`, `4d6dl1`, `2d20kh1`, `d6!`, `4dF`, `d%`, `5d10>=7=3`
    dice: (_) => token(prec(PREC_VALUE, DICE)),

    // `vs`, `>=`, `<=`, `≥`, `≤`
    comparison: (_) => token(prec(PREC_VALUE, choice('vs', '>=', '<=', '≥', '≤'))),

    _number: (_) => /\d+/,
    _word: (_) => /[^\s\[\]()"“”\d=]+/,
    // Includes quotes that don't close on their line (multi-line excerpts).
    _punctuation: (_) => choice('[', ']', '(', ')', '=', '"', '“', '”'),
  },
});
