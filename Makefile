all: P05_Serial

CC = nvcc
#CFLAGS = 
short_N = 2 4 8 16 32 64
full_N = 2 4 8 16 32 64 128 256 512 1024

P05_Serial: P05_Serial.o
	$(CC) P05_Serial.o -o P05_Serial -lm -L/usr/local/cuda/targets/x86_64-linux/lib -lcudart

P05_Serial.o: P05_Serial.cu
	$(CC) -c P05_Serial.cu -o P05_Serial.o

run:	P05_Serial
	./P05_Serial 4

short_run_multi:	P05_Serial
		@echo "P05 with different thread counts" > short_output.log
		@for n in $(short_N); do \
			echo "Running with  2^$$n elements..." >&2; \
			nohup ./P05_Serial $$n >> short_output.log; \
			echo "" >> short_output.log; \
		done

full_run_multi:	P05_Serial
		@echo "P05 with different thread coutns" > long_output.log
		@for n in $(full_N); do \
			echo "Running with  2^$$n elements..." >&2; \
			nohup ./P05_Serial $$n >> long_output.log; \
			echo "" >> long_output.log; \
		done

