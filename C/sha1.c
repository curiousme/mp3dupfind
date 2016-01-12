#include <stdio.h>
#include <openssl/sha.h>

#define MIN(a,b) ((a) < (b) ? a : b)

int HashStream(FILE *fp, unsigned char *hash, int bytes_to_read)
{
	SHA_CTX ctx;
	const int CHUNK_SIZE = 1*1024;
	unsigned char chunk[CHUNK_SIZE];
	int bytes_read;
	int total_read = 0;

	SHA1_Init(&ctx);
	while (bytes_to_read > 0 && (bytes_read = fread(chunk, sizeof(char), MIN(bytes_to_read, sizeof(chunk)), fp)) != 0) {
		SHA1_Update(&ctx, chunk, bytes_read);
		total_read += bytes_read;
		bytes_to_read -= bytes_read;
	}
	SHA1_Final(hash, &ctx);

	return total_read;
}

int HashFile(const char * fname, unsigned char *hash, int bytes_to_read)
{
	FILE *fp = fopen(fname, "rb");
	if (fp != NULL) {
		int total_read = HashStream(fp, hash, bytes_to_read);
		fclose(fp);
		return total_read;
	} else {
		return -1;
	}
}
