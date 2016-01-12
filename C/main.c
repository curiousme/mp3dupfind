#include<stdlib.h>
#include<stdio.h>
#include<sys/types.h>
#include<sys/stat.h>
#include<fts.h>
#include<string.h>
#include<errno.h>
#include<err.h>

#include "sha1.c"

const int HASHED_SEGMENT = 256 * 1024;

typedef void (*process_file)(const char*);

int traverse(char * const argv[], void (*process_file)(const char* path));
void read_hash(const char *path);

int main(int argc, char* const argv[])
{
	if (argc < 2) {
		printf("Usage: %s <path-spec>\n", argv[0]);
		exit(255);
	}

	int rc = 0;
	// argv + 1 is the smae as &argv[1] -- pointer to the second element of the array.
	if ((rc = traverse(argv + 1, &read_hash)) != 0)
			rc = 1;

	return rc;
}

void read_hash(const char *path)
{
	int total_read;
	unsigned char hash[SHA_DIGEST_LENGTH];

	if ((total_read = HashFile(path, hash, HASHED_SEGMENT)) > -1) {
		for (int i = 0; i < SHA_DIGEST_LENGTH; i++) printf("%02x", hash[i]);
		printf(" in %d bytes", total_read);
		printf("\n");
	} else {
		printf("Failed to read, got -1");
	}
}

int traverse(char* const argv[], void (*process_file)(const char *path))
{
	FTS *ftsp = NULL;
	FTSENT *child = NULL;

	if ((ftsp = fts_open(argv, FTS_COMFOLLOW | FTS_NOCHDIR | FTS_XDEV, NULL)) == NULL) {
		warn("fts_open");
		return -1;
	}

	while ((child = fts_read(ftsp)) != NULL) {
		if (errno != 0) {
			perror("fts_read");
		}
		switch(child->fts_info) {
			case FTS_F :
			//	printf("%d     %s\t\t\t", child->fts_level, child->fts_name);
				process_file(child->fts_path);
				break;
			//case FTS_D :
			//	printf("%d %s\n", child->fts_level, child->fts_path);
			//	break;
			default :
				break;
		}
	}
	fts_close(ftsp);
	return 0;
}
