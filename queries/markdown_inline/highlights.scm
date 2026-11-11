; extends

; markdown_inline reads Lonelog tags in paragraphs (`[N:Jonah|friendly]`) as shortcut links.
; `@lonelog.tag` is a `nocombine` group with no style of its own (see lua/lonelog/init.lua): it
; sits just above the link highlights and stops their underline/bold/italic merging into the tag.
; Lonelog's own tag captures (priority 105+) then style it.
((shortcut_link) @lonelog.tag
  (#lonelog-buffer? @lonelog.tag)
  (#lua-match? @lonelog.tag "^%[#?%u%a*:")
  (#set! priority 104))

; It also conceals their brackets. In Lonelog buffers, re-conceal each bracket as itself at a higher
; priority so tags stay readable with 'conceallevel' set.
((shortcut_link
  "[" @lonelog.tag) @_link
  (#lonelog-buffer? @_link)
  (#lua-match? @_link "^%[#?%u%a*:")
  (#set! @lonelog.tag conceal "[")
  (#set! priority 120))

((shortcut_link
  "]" @lonelog.tag) @_link
  (#lonelog-buffer? @_link)
  (#lua-match? @_link "^%[#?%u%a*:")
  (#set! @lonelog.tag conceal "]")
  (#set! priority 120))
