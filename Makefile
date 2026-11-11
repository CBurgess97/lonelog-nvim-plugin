GRAMMAR := tree-sitter-lonelog
CFLAGS ?= -O2

.PHONY: all generate test parser test-nvim lint check update-corpus clean

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
	nvim --headless --clean --cmd 'set rtp^=.' -c 'luafile test/nvim_spec.lua'

lint:
	luacheck -q .
	stylua --check lua plugin ftplugin test

# Everything to run before a commit.
check: test test-nvim lint

# Rewrite the expected trees in the corpus from the current parser. Review the diff afterwards.
# Lonelog uses `===` and `---` lines itself, so the corpus files use `|||`-suffixed delimiters;
# `tree-sitter test --update` strips the suffix, which silently drops those files from the run.
update-corpus: generate
	-cd $(GRAMMAR) && tree-sitter test --update >/dev/null
	sed -i 's/^==================$$/==================|||/; s/^---$$/---|||/' $(GRAMMAR)/test/corpus/*.txt
	cd $(GRAMMAR) && tree-sitter test

clean:
	rm -rf parser
