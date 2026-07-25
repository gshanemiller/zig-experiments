#include <simdjson.h>
#include <stringzilla.h>
#include <json_binding.h>
#include <assert.h>

class JSONDocument {
  // data
  simdjson::ondemand::document doc;
  simdjson::ondemand::parser parser;
  std::string_view stringValue;
public:
  // CREATORS
  JSONDocument() = default;
  ~JSONDocument() = default; 
public:
  // MANIPULATORS
  int reset(const char *data, const size_t dataSize);
  int findStringValue(const char *key, const size_t keySize);
  int findNestedStringValue(int keyCount, const char *key, const size_t *keySize);
};

int JSONDocument::reset(const char *data, const size_t dataSize) {
  assert(data);
  assert(dataSize);
  return parser.iterate(data, dataSize).get(doc);
}

int JSONDocument::findStringValue(const char *key, const size_t keySize) {
  assert(key);
  assert(keySize);
  auto result = doc[std::string_view(key, keySize)];
  if (0==result.error()) {
    result.get(stringValue);
    return 0;
  }
  return -1;
}

int JSONDocument::findNestedStringValue(int keyCount, const char *key, const size_t *keySize) {
  assert(keyCount>0);
  assert(key);
  assert(keySize);
  return 0;
}

extern "C" {

void *infinitech_createJsonDocument() {
  return new JSONDocument;
}

int infinitech_resetJsonDocument(void *handle, const char *data, const size_t dataSize) {
  assert(handle);
  return static_cast<JSONDocument*>(handle)->reset(data, dataSize);
}

int infinitech_findJsonStringValue(void *handle, const char *key, const size_t keySize) {
  assert(handle);
  return static_cast<JSONDocument*>(handle)->findStringValue(key, keySize);
}

int infinitech_findJsonNestedStringValue(void *handle, int keyCount, const char *key, const size_t *keySize) {
  assert(handle);
  return static_cast<JSONDocument*>(handle)->findNestedStringValue(keyCount, key, keySize);
}

int infinitech_stripJsonWhiteSpace(const char *data, const size_t dataSize, char *output, size_t *outputSize) {
  assert(data);
  assert(dataSize);
  assert(output);
  assert(outputSize);
  std::size_t outputLen = *outputSize;
  if (0==simdjson::minify(data, dataSize, (char*)output, outputLen)) {
    *outputSize = outputLen;
    return 0;
  }
  return -1;
}

const char *infinitech_strstr(const char *data, const size_t dataSize, const char *key, const size_t keySize) {
  assert(data);
  assert(dataSize);
  assert(key);
  assert(keySize);
  return sz_find(data, dataSize, key, keySize);
}

};
