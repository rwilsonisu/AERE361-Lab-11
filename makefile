CC = gcc
CCFLAGS = -Wall -Werror -Wextra -std=c99

all: solver

solver: solver.c
	$(CC) $(CCFLAGS) solver.c -o solver

clean:
	rm -f solver *.o matrix.txt b.txt solution.txt answer.csv edges.txt
