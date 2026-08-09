WRAP_SYMS := $(shell grep -ohrE '^fun crystal_[A-Za-z0-9_]+' --include='*.cr' src | sed -E 's/^fun crystal_//')

.PHONY: all
all: libpuredoom.dylib
	shards install
	crystal build src/libdoom-cr.cr --link-flags "-fuse-ld=/opt/homebrew/opt/lld/bin/ld64.lld" -o bin/libdoom
	mv -f libpuredoom.dylib ./bin
	cd ./bin && \
	./libdoom

libpuredoom.dylib:
	cc -shared -fPIC -x c \
		-Wl,-undefined,dynamic_lookup \
		-DDOOM_IMPLEMENTATION \
		-DDOOM_IMPLEMENT_MALLOC \
		-DDOOM_IMPLEMENT_FILE_IO \
		-DDOOM_IMPLEMENT_GETTIME \
		-DDOOM_IMPLEMENT_EXIT \
		-DDOOM_IMPLEMENT_GETENV \
			PureDoom.h -o libpuredoom.dylib
