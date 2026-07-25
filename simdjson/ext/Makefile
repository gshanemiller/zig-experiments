.PHONY: clean

AR=x86_64-linux-gnu-ar

C=clang-19
CPP=clang++-19

C_DEBUG_OPTS=-O0 -g -march=native -mtune=native
CPP_DEBUG_OPTS=-O0 -g -march=native -mtune=native

C_RELEASE_SAFE_OPTS=-O2 -march=native -mtune=native
CPP_RELEASE_SAFE_OPTS=-O2 -march=native -mtune=native

C_RELEASE_FAST_OPTS=-O2 -DNDEBUG -march=native -mtune=native
CPP_RELEASE_FAST_OPTS=-O2 -DNDEBUG -march=native -mtune=native

STRINGZILLA_CPU=-DSZ_USE_HASWELL=1

all: libjson.debug.a

libjson.debug.a:
	${CPP} ${CPP_DEBUG_OPTS} -DSIMDJSON_EXCEPTIONS=0 -Ijson -Ijson/stringzilla -Ijson/simdjson -c json/json.cpp -o json/json.debugcpp.o
	${CPP} ${CPP_DEBUG_OPTS} -DSIMDJSON_EXCEPTIONS=0 -Ijson -Ijson/simdjson -c json/simdjson/simdjson.cpp -o json/simdjson/json.debug.o
	${AR} rcs json/libjson.debug.a json/json.debugcpp.o json/simdjson/json.debug.o
main: libjson.debug.a
	${C} ${C_DEBUG_OPTS} -Ijson json/main.c -o json/main -Ljson -ljson.debug -lstdc++

clean:
	rm -f */*.o */*.a json/main
