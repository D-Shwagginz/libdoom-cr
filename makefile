WRAP_SYMS := $(shell grep -ohrE '^fun crystal_[A-Za-z0-9_]+' --include='*.cr' src | sed -E 's/^fun crystal_//')

.PHONY: all
all: build/glue.c build/glue.o libpuredoom.dylib
	shards install
	crystal build src/libdoom-cr.cr --link-flags "-fuse-ld=/opt/homebrew/opt/lld/bin/ld64.lld" -o bin/libdoom
	rm -rf build
	mv -f libpuredoom.dylib ./bin
	cd ./bin && \
	./libdoom


build/glue.c: src/*.cr
	@mkdir -p build
	@printf '%s\n' '#include <stddef.h>' > build/glue.c
	@printf '%s\n' '' >> build/glue.c
	@for sym in $(WRAP_SYMS); do \
		printf '%s\n' "extern void crystal_$$sym(void);" >> build/glue.c; \
		printf '%s\n' "void $$sym(void) { crystal_$$sym(); }" >> build/glue.c; \
	done
	cc -c build/glue.c -o build/glue.o

libpuredoom.dylib:
	cp ./OrigPureDoom.h ./PureDoom.h
	@mkdir -p build
	@touch build/decls.h
	@for sym in $(WRAP_SYMS); do \
		printf '%s\n' "extern void $$sym(void);" >> build/decls.h; \
	done
	@for sym in $(WRAP_SYMS); do \
		sed -i '' "s/^void $$sym(void)\$$/void PureDoom_$$sym""_orig(void)/" PureDoom.h; \
	done
	@cp PureDoom.h PureDoom.h.orig
	@cat build/decls.h PureDoom.h.orig > PureDoom.h
	@rm PureDoom.h.orig
	cc -shared -fPIC -x c \
		-Wl,-undefined,dynamic_lookup \
		-DDOOM_IMPLEMENTATION \
		-DDOOM_IMPLEMENT_PRINT \
		-DDOOM_IMPLEMENT_MALLOC \
		-DDOOM_IMPLEMENT_FILE_IO \
		-DDOOM_IMPLEMENT_GETTIME \
		-DDOOM_IMPLEMENT_EXIT \
		-DDOOM_IMPLEMENT_GETENV \
			PureDoom.h -o libpuredoom.dylib
	rm PureDoom.h