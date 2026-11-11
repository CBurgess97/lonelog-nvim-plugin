; extends

; markdown_inline reads Lonelog tags in paragraphs (`[N:Jonah|friendly]`) as shortcut links and
; conceals their brackets. In Lonelog buffers, re-conceal each bracket as itself at a higher
; priority so tags stay readable with 'conceallevel' set.
((shortcut_link
  "[" @markup.link) @_link
  (#lonelog-buffer? @_link)
  (#lua-match? @_link "^%[#?%u%a*:")
  (#set! @markup.link conceal "[")
  (#set! priority 120))

((shortcut_link
  "]" @markup.link) @_link
  (#lonelog-buffer? @_link)
  (#lua-match? @_link "^%[#?%u%a*:")
  (#set! @markup.link conceal "]")
  (#set! priority 120))
