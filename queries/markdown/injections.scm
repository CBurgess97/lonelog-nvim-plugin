; extends

; Lonelog notation in `markdown.lonelog` buffers. A fence tagged `lonelog` works in any markdown
; buffer through the standard info-string injection.

; Untagged fenced code blocks (the delimiter is followed directly by content, not an info string)
((fenced_code_block
  .
  (fenced_code_block_delimiter)
  .
  (block_continuation)
  .
  (code_fence_content) @injection.content)
  (#lonelog-buffer? @injection.content)
  (#set! injection.language "lonelog"))

; Indented code blocks
((indented_code_block) @injection.content
  (#lonelog-buffer? @injection.content)
  (#set! injection.language "lonelog"))

; Notation written straight into paragraphs
((paragraph
  (inline) @injection.content)
  (#lonelog-buffer? @injection.content)
  (#set! injection.language "lonelog"))
