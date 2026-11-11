; Line markers
(action
  marker: _ @keyword)

(actor) @variable.parameter

(question
  marker: _ @keyword)

(roll
  marker: _ @function)

(consequence
  marker: _ @operator)

[
  (table
    marker: _)
  (generator
    marker: _)
] @function.builtin

(entry_key) @number @nospell

(outcome
  arrow: _ @operator)

(speaker) @label

(scene_id) @markup.heading @nospell

(session_header) @markup.heading

[
  (block_marker)
  (excerpt_delimiter)
] @punctuation.special

; Values
(dice) @number @nospell

(comparison) @keyword.operator

(string) @string

(meta_note) @comment

; Tags. Priority beats markdown_inline, which reads `[N:...]` in paragraphs as a link.
((tag_open) @type @nospell
  (#set! priority 110))

((tag
  "]" @type)
  (#set! priority 110))

((tag_text) @variable.member
  (#set! priority 105))

((tag
  .
  (tag_open)
  .
  (tag_text) @label)
  (#set! priority 110))

((tag_key) @property
  (#set! priority 110))

((tag_separator) @punctuation.delimiter
  (#set! priority 110))

((progress) @number @nospell
  (#set! priority 110))
