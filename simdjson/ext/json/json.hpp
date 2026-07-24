#pragma once
#include <simdjson.h>
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
