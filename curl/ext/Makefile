.PHONY: clean

DEFINES=-DSIMDJSON_AVX512_ALLOWED=0 -DSIMDJSON_IMPLEMENTATION_HASWELL=1 -DSIMDJSON_EXCEPTIONS=0 -DSZ_USE_HASWELL=1 -DSZ_AVOID_LIBC=0 -DINFINITECH_LOG_LEVEL=3

# Make sure it compiles outside zig
all:
	clang++-19 -O2 ${DEFINES} -Wall -Werror -Wpedantic -Isrc -c src/io.cpp -o src/io.o
	clang++-19 -O2 ${DEFINES} -Wall -Werror -Wpedantic -Isrc -c src/curl.cpp -o src/curl.o
	clang++-19 -O2 ${DEFINES} -Wall -Werror -Wpedantic -Isrc -c src/thread.cpp -o src/thread.o
	clang++-19 -O2 ${DEFINES} -Wall -Werror -Wpedantic -Isrc -c src/thread.cpp -o src/memory.o
	clang++-19 -O2 ${DEFINES} -Wall -Werror -Wpedantic -Isrc -Isrc/simdjson -Isrc/stringzilla -c src/json.cpp -o src/json.o
	clang++-19 -O2 ${DEFINES} -Wall -Werror -Wpedantic -Isrc -Isrc/simdjson -c src/simdjson/simdjson.cpp -o src/simdjson/simdjson.o
	ar rcs libext.a src/io.o src/curl.o src/thread.o src/memory.o src/json.o src/simdjson/simdjson.o

clean:
	rm -f src/io.o src/curl.o src/thread.o src/memory.o src/json.o src/simdjson/simdjson.o libext.a
