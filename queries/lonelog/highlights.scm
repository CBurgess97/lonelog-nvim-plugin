; Line and segment markers
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

; Structure
[
  (scene_id)
  (round_id)
] @markup.heading @nospell

(session_header) @markup.heading

(field_name) @property

(block_tag) @keyword.directive @nospell

[
  (block_marker)
  (excerpt_delimiter)
] @punctuation.special

; Values
(comparison) @keyword.operator

(string) @string

(meta_note) @comment

; The card token includes its leading `=`; highlight only the card.
((card) @constant @nospell
  (#offset! @constant 0 1 0 0))

; Tags. Whole name and attributes first, then the pieces inside them at a higher priority.
((tag_name) @label
  (#set! priority 105))

((tag_attribute) @variable.member
  (#set! priority 105))

((tag_open) @type @nospell
  (#set! priority 110))

((tag
  "]" @type)
  (#set! priority 110))

((tag_key) @property
  (#set! priority 110))

((tag_separator) @punctuation.delimiter
  (#set! priority 110))

([
  (dice)
  (progress)
  (delta)
  (multiplier)
] @number @nospell
  (#set! priority 110))

((transition) @operator
  (#set! priority 110))
