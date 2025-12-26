CC = gcc
CFLAGS = -Wall -O2 -std=c99

TARGETS = test_gemm gemm_cli test_tile test_cycle

COMMON_SRCS = gemm.c

all: $(TARGETS)

test_gemm: test_gemm.o gemm.o
	$(CC) $(CFLAGS) -o $@ $^

gemm_cli: gemm_cli.o gemm.o
	$(CC) $(CFLAGS) -o $@ $^

%.o: %.c gemm.h
	$(CC) $(CFLAGS) -c $<

clean:
	rm -f $(TARGETS) *.o

run: test_gemm
	./test_gemm

.PHONY: all clean run

test_tile: test_tile.o gemm.o gemm_tile.o
		$(CC) $(CFLAGS) -o $@ $^

test_cycle: test_cycle.o gemm.o gemm_cycle.o
	$(CC) $(CFLAGS) -o $@ $^

