.PHONY: all
all: libpuredoom.dylib
	shards install
	crystal build src/libdoom-cr.cr --link-flags "-fuse-ld=/opt/homebrew/opt/lld/bin/ld64.lld" -o bin/libdoom
	-cp rsrc/libADLMIDI.dylib ./bin
	mv -f libpuredoom.dylib ./bin
	cd ./bin && \
	./libdoom

libpuredoom.dylib:
	cc -shared -fPIC -x c \
		-Wl,-undefined,dynamic_lookup \
		-DDOOM_IMPLEMENTATION \
			PureDoom.h -o libpuredoom.dylib

