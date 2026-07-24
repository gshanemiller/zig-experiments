#include <assert.h>
#include <stringzilla.h>

const char *infinitech_strstr(const char *data, const size_t dataSize, const char *key, const size_t keySize) {
  assert(data);
  assert(dataSize);
  assert(key);
  assert(keySize);
  return sz_find(data, dataSize, key, keySize);
}
