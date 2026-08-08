#include <binding.h>
#include <numa.h>
#include <assert.h>
#include <sys/mman.h>

#ifdef __cplusplus
extern "C" {
#endif

void infinitech_zero(void *ptr, size_t size) {
  assert(ptr);
  assert(size>0);
  memset(ptr, 0, size);
}

void *infinitech_hugePageAlloc(size_t pageCount, size_t pageSizeKb) {
  assert(pageCount);
  assert(pageSizeKb);

  int protFlags = PROT_READ|PROT_WRITE;
  int flags = MAP_PRIVATE|MAP_ANONYMOUS|MAP_HUGETLB;
  const size_t capacity = pageCount*pageSizeKb*1024ULL;
  void *ptr = mmap(0, capacity, protFlags, flags, -1, 0);

  if (ptr==(void*)(0xffffffffffffffff)) {
    int rc = errno;
    infinitech_logError("hugePageAlloc capacity %lu bytes (%lu pages * %lu Kb/page) failed: %s (errno==%d)\n",
      capacity, pageCount, pageSizeKb, strerror(rc), rc);
    ptr = 0;
  } else {
    infinitech_logDebug("hugePageAlloc capacity %lu bytes (%lu pages * %lu Kb/page) at 0x%p\n",
      capacity, pageCount, pageSizeKb, ptr);
  }
  return ptr;
}

int infinitech_hugePageFree(void *ptr, size_t pageCount, size_t pageSizeKb) {
  assert(ptr);
  assert(pageCount);
  assert(pageSizeKb);

  const size_t capacity = pageCount*pageSizeKb*1024ULL;
  int rc = munmap(ptr, capacity);
  if (rc!=0) {
    rc = errno;
    infinitech_logError("hugePageFree capacity %lu bytes (%lu pages * %lu Kb/page) at 0x%p failed: %s (errno==%d)\n",
      capacity, pageCount, pageSizeKb, ptr, strerror(rc), rc);
  } else {
    infinitech_logDebug("hugePageFree capacity %lu bytes (%lu pages * %lu Kb/page) at 0x%p\n",
      capacity, pageCount, pageSizeKb, ptr);
  }
  return rc;
}

#ifdef __cplusplus
};
#endif
