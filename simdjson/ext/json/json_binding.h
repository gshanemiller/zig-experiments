#pragma once
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

void *infinitech_createJsonDocument();
int infinitech_resetJsonDocument(void *handle, const char *data, const size_t dataSize);
int infinitech_findJsonStringValue(void *handle, const char *key, const size_t keySize);
int infinitech_findJsonNestedStringValue(void *handle, int keyCount, const char *key, const size_t *keySize);
int infinitech_stripJsonWhiteSpace(const char *data, const size_t dataSize, char *output, size_t *outputSize);
const char *infinitech_strstr(const char *data, const size_t dataSize, const char *key, const size_t keySize);

#ifdef __cplusplus
};
#endif
