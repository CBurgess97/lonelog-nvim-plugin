; extends

; markdown_inline reads bracketed Lonelog notation in paragraphs (`[N:Jonah|friendly]`, `[COMBAT]`,
; `[Date]`, `[+cover, -injured]`) as shortcut links. In Lonelog buffers every shortcut link gets
; `@lonelog.tag`, a `nocombine` group with no style of its own (see lua/lonelog/init.lua): it sits
; just above the link highlights and stops their underline/bold/italic merging into the notation.
; Lonelog's own captures (priority 105+) then style it. Inline links `[text](url)` are untouched.
((shortcut_link) @lonelog.tag
  (#lonelog-buffer? @lonelog.tag)
  (#set! priority 104))

; markdown_inline also conceals the brackets. Re-conceal each bracket as itself at a higher
; priority so the notation stays readable with 'conceallevel' set.
((shortcut_link
  "[" @lonelog.tag)
  (#lonelog-buffer? @lonelog.tag)
  (#set! @lonelog.tag conceal "[")
  (#set! priority 120))

((shortcut_link
  "]" @lonelog.tag)
  (#lonelog-buffer? @lonelog.tag)
  (#set! @lonelog.tag conceal "]")
  (#set! priority 120))
