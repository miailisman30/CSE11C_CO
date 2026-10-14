CC = gcc
objects = build/main.o build/diff.o build/read_file.o
.PHONY: clean

diff: $(objects)
	$(CC) -no-pie -o "$@" $^

build:
	mkdir build

build/%.o: %.s | build
	$(CC) -g -no-pie -c -o "$@" "$<"

clean:
	rm -rf diff build
