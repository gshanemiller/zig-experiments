#include <stdio.h>
#include <errno.h>
#include <numa.h>

int main(int argc, char **argv) {
  void *ptr = numa_alloc_onnode(4096, 0);
  printf("got %p errno %d %s\n", ptr, errno, strerror(errno));
  numa_free(ptr, 4096);
  printf("sizeof(size_t) %lu sizeof(int) %lu sizeof(void*) %lu\n", sizeof(size_t), sizeof(int), sizeof(void *)); 
  return 0;
}
