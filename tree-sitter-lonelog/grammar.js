/**
 * Tree-sitter grammar for Lonelog 1.5.0 notation (https://lonelog.readthedocs.io).
 *
 * Line-oriented and forgiving: any line that isn't a recognised Lonelog line parses as
 * `text_line`, so prose never produces error nodes. Inline elements (tags, dice, outcomes,
 * meta notes) are recognised anywhere in a line.
 *
 * Lexical precedence (higher wins regardless of match length):
 *   4  line-start markers and structural lines
 *   3  inline constructs that open with punctuation ([N:, (note:, strings)
 *   2  dice, comparisons
 *   0  plain words / numbers / punctuation
 */

/* eslint-disable no-undef */

const PREC_LINE = 4;
const PREC_INLINE = 3;
const PREC_VALUE = 2;

module.exports = grammar({
  name: 'lonelog',

  // Newlines are significant (lines are the unit of notation), so only horizontal space is extra.
  extras: (_) => [/[ \t]/],

  rules: {
    source_file: ($) => seq(optional($._line), repeat(seq($._newline, optional($._line)))),

    _newline: (_) => /\r?\n/,

    _line: ($) =>
      choice(
        $.action,
        $.question,
        $.roll,
        $.consequence,
        $.table,
        $.generator,
        $.table_entry,
        $.dialogue,
        $.scene,
        $.session_header,
        $.block_marker,
        $.excerpt_delimiter,
        $.aside,
        $.text_line,
      ),

    // §3.1 `@ Pick the lock`, `@(Jonah) Keeps watch`
    action: ($) =>
      seq(
        field('marker', alias(token(prec(PREC_LINE, '@')), '@')),
        optional(field('actor', $.actor)),
        optional($._content),
      ),
    actor: (_) => token.immediate(/\([^)\n]+\)/),

    // §3.1 `? Is anyone inside?`
    question: ($) =>
      seq(field('marker', alias(token(prec(PREC_LINE, '?')), '?')), optional($._content)),

    // §3.2.1 `d: Stealth d6=5 vs TN 4 -> Success`
    roll: ($) =>
      seq(field('marker', alias(token(prec(PREC_LINE, 'd:')), 'd:')), optional($._content)),

    // §3.3 `=> The door creaks open`
    consequence: ($) =>
      seq(field('marker', alias(token(prec(PREC_LINE, '=>')), '=>')), optional($._content)),

    // §4.3 `tbl: d100=42 -> "A broken sword"`, `gen: NPC -> Merchant`
    table: ($) =>
      seq(field('marker', alias(token(prec(PREC_LINE, 'tbl:')), 'tbl:')), optional($._content)),
    generator: ($) =>
      seq(field('marker', alias(token(prec(PREC_LINE, 'gen:')), 'gen:')), optional($._content)),

    // §4.3.1 inline table rows: `1-2: Nothing — eerie silence`
    table_entry: ($) =>
      seq(field('key', alias(token(prec(PREC_LINE, /\d+(-\d+)?:/)), $.entry_key)), optional($._content)),

    // §4.4 `N (Guard): "Who's there?"`, `PC: "Stay calm"`
    dialogue: ($) => seq(field('speaker', $.speaker), optional($._content)),
    speaker: (_) => token(prec(PREC_LINE, /(PC|N)( ?\([^)\n]*\))?:/)),

    // §5.3 analog scene markers: `S1`, `S5a`, `S7.1`, `T1-S2`, `T1+T2-S5`
    scene: ($) => seq(field('id', $.scene_id), optional($._content)),
    scene_id: (_) => token(prec(PREC_LINE, /(T\d+(\+T\d+)*-)?S\d+([a-z]|\.\d+)?/)),

    // §5.2.2 `=== Session 1 ===`
    session_header: (_) => token(prec(PREC_LINE, /===[^\n]*===/)),

    // Add-on block markers: `--- RESOURCES ---`, `--- END COMBAT ---`
    block_marker: (_) => token(prec(PREC_LINE, /---[ \t]+[^\n]*[ \t]---/)),

    // §4.4 narrative excerpt fences `\---` ... `---\`
    excerpt_delimiter: (_) => token(prec(PREC_LINE, choice('\\---', '---\\'))),

    // Anything else: prose, or a line that is just tags / a meta note.
    text_line: ($) => $._content,

    _content: ($) => repeat1($._inline),

    _inline: ($) =>
      choice(
        $.outcome,
        $.tag,
        $.meta_note,
        $.string,
        $.dice,
        $.comparison,
        $._number,
        $._word,
        $._punctuation,
      ),

    // §3.2.2 `-> Success`, `-> Yes, but... (d6=4)`; runs to end of line.
    outcome: ($) =>
      prec.right(seq(field('arrow', alias(token(prec(PREC_LINE, '->')), '->')), repeat($._inline))),

    // §4.1 / §4.2 `[N:Jonah|friendly]`, `[#N:Jonah]`, `[Clock:Ritual 5/12]`, multi-line tags.
    tag: ($) =>
      seq(
        field('open', $.tag_open),
        repeat(
          choice(
            $.tag_text,
            $.tag_key,
            $.progress,
            alias('|', $.tag_separator),
            $._tag_continuation,
          ),
        ),
        choice(']', $._tag_close_line),
      ),
    // A multi-line tag continues only onto an indented line or a line starting with `]` (§4.1.8),
    // so an unclosed `[N:...` can't swallow the lines after it.
    _tag_continuation: (_) => token(prec(PREC_INLINE, /\r?\n[ \t]+/)),
    _tag_close_line: (_) => token(prec(PREC_INLINE, /\r?\n\]/)),
    tag_open: (_) => token(prec(PREC_INLINE, /\[#?[A-Z][A-Za-z]*:/)),
    tag_key: (_) => token(prec(PREC_VALUE, /[a-z][A-Za-z ]*:/)),
    tag_text: (_) => /[^|\]\n\d \t][^|\]\n\d]*|\d+/,
    progress: (_) => token(prec(PREC_VALUE, /\d+\/\d+/)),

    // §4.5 `(note: testing a house rule)` anywhere in a line.
    meta_note: (_) => token(prec(PREC_INLINE, /\([a-z][a-z ]*:[^)\n]*\)/)),

    // §4.5 / §5.3 a line opening with a bare aside: `(Memory triggered by the photograph)`.
    // Mid-line `(d6=4)` roll references stay plain text.
    aside: ($) =>
      seq(
        alias(token(prec(PREC_LINE, /\([^)\n]*\)/)), $.meta_note),
        optional($._content),
      ),

    string: (_) => token(prec(PREC_INLINE, choice(/"[^"\n]*"/, /“[^”\n]*”/))),

    // `d6`, `2d6=8`, `d100=42`
    dice: (_) => token(prec(PREC_VALUE, /\d*[dD]\d+(=\d+)?/)),

    // `vs`, `>=`, `<=`, `≥`, `≤`
    comparison: (_) => token(prec(PREC_VALUE, choice('vs', '>=', '<=', '≥', '≤'))),

    _number: (_) => /\d+/,
    _word: (_) => /[^\s\[\]()"“”\d]+/,
    _punctuation: (_) => choice('[', ']', '(', ')'),
  },
});
