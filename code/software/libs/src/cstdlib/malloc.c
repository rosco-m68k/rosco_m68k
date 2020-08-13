// very basic malloc implementation (does not free)

#include <stdlib.h>
#include <string.h>

extern char _end[];
char* __sbrk = _end;

enum { BLK_MAGIC = 0xBADC0DE };

typedef struct _memblk {
	struct _memblk	*blk_next;
	struct _memblk	*blk_prev;
	size_t			blk_size;
	unsigned long	blk_magic;
} memblk_t;

void* malloc(size_t size) {
	size = (size + sizeof (long)-1) & ~(sizeof (long)-1);

	memblk_t *blk = (memblk_t *)__sbrk;

	blk->blk_next = NULL;	// TODO
	blk->blk_prev = NULL;	// TODO
	blk->blk_size = size;
	blk->blk_magic = BLK_MAGIC;

	__sbrk += sizeof (memblk_t) + size;

	return &blk[1];
}

// NOTE: not actually implmented
void free(void *ptr)
{
	memblk_t *blk = ((memblk_t *)ptr)-1;
	if (blk->blk_magic != BLK_MAGIC)
		abort();
}

void* realloc(void *ptr, size_t size)
{
	return malloc(size);
}

void* calloc(size_t num , size_t size)
{
#if 1	// multiply not working in this compiler yet
	size_t bsize = size * num;
#else
	size_t bsize = 0;
	for (int i = 0; i < num; i++)
		bsize += size;
#endif
	void *ptr = malloc(bsize);
	memset(ptr, 0, bsize);
	return ptr;
}
