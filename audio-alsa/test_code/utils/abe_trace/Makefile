TARGETS := abe_trace

all: $(TARGETS)

abe_trace:
	$(CROSS_COMPILE)gcc abe_trace.c -o abe_trace -lm -static

clean:
	 -rm -f *.o $(TARGETS)
