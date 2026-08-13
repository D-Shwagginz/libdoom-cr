.PHONY: all
all: libpuredoom.dylib
	shards install
	crystal build src/libdoom-cr.cr --link-flags "-fuse-ld=/opt/homebrew/opt/lld/bin/ld64.lld" -o bin/libdoom
	mv -f libpuredoom.dylib ./bin
	-cp ./rsrc/libADLMIDI.dylib ./bin
	install_name_tool -change "@rpath/libADLMIDI.1.dylib" "./libADLMIDI.dylib" ./bin/libdoom

	cd ./bin && \
	./libdoom -warp 30

libpuredoom.dylib:
	cc -shared -fPIC -x c \
		-Wl,-undefined,dynamic_lookup \
		-DDOOM_IMPLEMENTATION \
			PureDoom.h -o libpuredoom.dylib

