#include <omp.h>
#include <stdio.h>
#include <math.h>
#include <stdlib.h>
#include <time.h> 
#include <float.h>
#include <cuda_runtime.h>
#include <device_launch_parameters.h>

#define BLOCK_SIZE 512 // You can change this

__global__ void kernel(float *input, float *output, int len) {
	// Load a segment of the input vector into shared memory
	__shared__ float partialSum[2 * BLOCK_SIZE];
	unsigned int t = threadIdx.x, start = 2 * blockIdx.x * BLOCK_SIZE;
	if (start + t < len)
		partialSum[t] = input[start + t];
	else
		partialSum[t] = 0;
	if (start + BLOCK_SIZE + t < len)
		partialSum[BLOCK_SIZE + t] = input[start + BLOCK_SIZE + t];
	else
		partialSum[BLOCK_SIZE + t] = 0;
	// Traverse the reduction tree

	/*	
	   strides will assume values:
	   512
	   256
	   128
	   64
	   32
	   16
	   8
	   4
	   2
	   1
	*/ 
	for (unsigned int stride = BLOCK_SIZE; stride >= 1; stride >>= 1) {
		__syncthreads();
		if (t < stride)
			partialSum[t] += partialSum[t + stride];
	}
	// Write the computed sum of the block to the output vector at the
	// correct index
	if (t == 0)
		output[blockIdx.x] = partialSum[0];
}

float summation(float *input, int len) {
	float sum = 0.0;
	for (int i = 0; i < len; i++){
		sum += input[i];
	}
	return sum;
}
/*
void write_to_csv(double *T, int n_cells, const char *filename) {
         FILE *file = fopen(filename, "w");
         if (!file) {
                 fprintf(stderr, "Error: could not open file %s for writing. \n", filename);
                 return;
         }

         for (unsigned i = 0; i <= n_cells + 1; i++){
                 for (unsigned j = 0; j <= n_cells + 1; j++) {
                         fprintf(file, "%.6f", T(i,j));
                         if (j < n_cells + 1){
                                 fprintf(file, ",");
                         }
                 }
                 fprintf(file, "\n");
         }

         fclose(file);
         printf("Matrix saved to %s\n", filename);



 }
*/

int main(int argc, char *argv[]){
	
	//Generating 2D array of length 2^N (Passed from user input) filled with random floats. Floats are set to values such that the summation won't overflow the maximum value for float
	int N = 0;
	sscanf(argv[1], "%d", &N);
	
	int len = (int)pow(2, N);
	
	float *input = (float*)malloc(len * sizeof(float));

	if (input == NULL) {
    		printf("Memory allocation failed! Exiting.\n");
    		return -1;
	}


	srand(time(NULL));
	for (int i = 0; i < len; i++){
		input[i] = ((FLT_MAX / len) * 0.999999) * ((float) rand() / RAND_MAX);
		
	}
	
	//Print out the array to check that it was initialized and filled correctly
	for (int i = 0; i < len; i++){
		printf("%f \n", input[i]);
	}
	

	//Run the serial kernel and output the computation time in ms
	clock_t t;
	t = clock();

	//kernel call
	float sum_serial = summation(input, len);
	
	//Output sum to verify valid run
	printf("Sum: %f \n", sum_serial);

	t = clock() - t;
	printf("2^%d elements CPU Serial elapsed time: %f ms\n", N, ((double)t/CLOCKS_PER_SEC * 1000));


	int numBlocks = (len + 2 * BLOCK_SIZE - 1) / (2 * BLOCK_SIZE);
	int numThreads = BLOCK_SIZE;
	float *d_output;
	cudaMalloc((void**)&d_output, sizeof(float));

	float *d_input;
	cudaMalloc((void**)&d_input, len * sizeof(float));
	cudaMemcpy(d_input, input, len * sizeof(float), cudaMemcpyHostToDevice);


	cudaEvent_t start, stop;
	float elapsedTime;

	cudaEventCreate(&start);
	cudaEventRecord(start,0);

	// call device kernel
	kernel<<<numBlocks, numThreads>>>(d_input, d_output, len);

	cudaEventCreate(&stop);
	cudaEventRecord(stop,0);
	cudaEventSynchronize(stop);

	cudaEventElapsedTime(&elapsedTime, start, stop);

	// Allocate memory for output sum on the host
	float output_CUDA = 0;

	// Copy result from GPU to CPU
	cudaMemcpy(&output_CUDA, d_output, sizeof(float), cudaMemcpyDeviceToHost);

	// Print the result
	printf("CUDA Sum: %f \n", output_CUDA);
	printf("2^%d elements CUDA elapsed time: %f ms\n", N, elapsedTime);
	
	//dim3 dimGrid((numOutputElements, 1, 1);
	//dim3 dimBlock((BLOCK_SIZE, 1, 1);
	//reduction<<<dimGrid, dimBlock>>>(deviceInput, deviceOutput, numInputElements);

}
