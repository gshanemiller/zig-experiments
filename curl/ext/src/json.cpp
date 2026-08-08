#include <simdjson.h>
#include <stringzilla.h>
#include <binding.h>
#include <assert.h>

class JSONDocument {
  // data
  simdjson::padded_string json;
  std::string_view stringValue;
  simdjson::ondemand::document doc;
  simdjson::ondemand::parser parser;
public:
  // CREATORS
  JSONDocument() = default;
  ~JSONDocument() = default;
public:
  // MANIPULATORS
  int reset(const char *data, const size_t dataSize);
  int findStringValue(const char *key, const size_t keyLength,
    struct StringRef *result);
  int findNestedStringValue(const char *key, const size_t keyLength,
    struct StringRef *result);
};

int JSONDocument::reset(const char *data, const size_t dataSize) {
  assert(data);
  assert(dataSize);
  json = simdjson::padded_string(data, dataSize);
  return parser.iterate(json).get(doc);
}

int JSONDocument::findStringValue(const char *key, const size_t keyLength,
  struct StringRef *result) {
  assert(key);
  assert(keyLength);
  assert(result);
  result->ptr = 0;
  result->len = 0;
  int rc = doc[std::string_view(key, keyLength)].get(stringValue);
  if (0==rc) {
    result->ptr = stringValue.data();
    result->len = stringValue.length();
  }
  return rc;
}

int JSONDocument::findNestedStringValue(const char *key, const size_t keyLength,
  struct StringRef *result) {
  assert(key);
  assert(keyLength);
  assert(result);
  result->ptr = 0;
  result->len = 0;
  int rc = doc.at_pointer(std::string_view(key, keyLength)).get(stringValue);
  if (0==rc) {
    result->ptr = stringValue.data();
    result->len = stringValue.length();
  }
  return rc;
}

extern "C" {

void *infinitech_createJsonDoc() {
  auto ptr = new JSONDocument;
  infinitech_logDebug("created JSONDocument object %p\n", (void*)ptr);
  return ptr;
}

void infinitech_destroyJsonDoc(void *handle) {
  assert(handle);
  infinitech_logDebug("destroying JSONDocument object %p\n", handle);
  delete static_cast<JSONDocument*>(handle);
}

int infinitech_resetJsonDoc(void *handle, const char *data, const size_t dataSize) {
  assert(handle);
  return static_cast<JSONDocument*>(handle)->reset(data, dataSize);
}

int infinitech_findJsonDocKeyValue(void *handle, const char *key, const size_t keyLength,
  struct StringRef *result) {
  assert(handle);
  return static_cast<JSONDocument*>(handle)->findStringValue(key, keyLength, result);
}

int infinitech_findJsonDocNestedKeyValue(void *handle, const char *key, const size_t keyLength,
  struct StringRef *result) {
  assert(handle);
  return static_cast<JSONDocument*>(handle)->findNestedStringValue(key, keyLength, result);
}

int infinitech_stripJsonWhiteSpace(const char *data, const size_t dataSize, char *output, size_t *outputSize) {
  assert(data);
  assert(dataSize);
  assert(output);
  assert(outputSize);
  assert(*outputSize>dataSize);
  std::size_t outputLen = *outputSize;
  if (0==simdjson::minify(data, dataSize, (char*)output, outputLen)) {
    *outputSize = outputLen;
    return 0;
  }
  return -1;
}

const char *infinitech_strstr(const char *data, const size_t dataSize, const char *key, const size_t keyLength) {
  assert(data);
  assert(dataSize);
  assert(key);
  assert(keyLength);
  return sz_find(data, dataSize, key, keyLength);
}

};
