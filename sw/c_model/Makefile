CC = gcc
CFLAGS = -Wall -O2 -std=c99

TARGETS = test_gemm gemm_cli
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

