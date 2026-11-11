GRAMMAR := tree-sitter-lonelog
CFLAGS ?= -O2

.PHONY: all generate test parser test-nvim clean

all: generate test parser

generate: $(GRAMMAR)/src/parser.c

$(GRAMMAR)/src/parser.c: $(GRAMMAR)/grammar.js
	cd $(GRAMMAR) && tree-sitter generate

test: generate
	cd $(GRAMMAR) && tree-sitter test

parser: parser/lonelog.so

parser/lonelog.so: $(GRAMMAR)/src/parser.c
	mkdir -p parser
	$(CC) $(CFLAGS) -shared -fPIC -I $(GRAMMAR)/src $(GRAMMAR)/src/parser.c -o $@

test-nvim: parser
	nvim --headless --clean --cmd 'set rtp^=.' -l test/nvim_spec.lua

clean:
	rm -rf parser
