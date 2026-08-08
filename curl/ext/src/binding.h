#pragma once
#include <stddef.h>
#include <stdarg.h>
#include <errno.h>
#include <sys/stat.h>
#include <sys/uio.h>
// #include <zlib/zlib.h>

#ifdef __cplusplus
extern "C" {
#endif

enum {
  // Maximum path length in bytes
  INFINITECH_MAXIMUM_PATH_LENGTH = 1023,
  // Maximum path size in bytes for C 0-terminated strings
  INFINITECH_MAXIMUM_PATH_SIZE = (INFINITECH_MAXIMUM_PATH_LENGTH+1),
  // Length in bytes appended to a tmpDir parentDir to make unique
  INFINITECH_TMPDIR_SUFFIX_LENGTH = 10,
  // Maximum tmpdir suffix size in bytes
  INFINITECH_TMPDIR_SUFFIX_SIZE = (INFINITECH_TMPDIR_SUFFIX_LENGTH+1),
};

struct StringRef {
  size_t len;
  const char *ptr;
};

typedef size_t (*infinitech_curl_callback)(size_t data, size_t size, size_t nmemb, size_t context);

// Logging
#ifndef INFINITECH_LOG_LEVEL
// Log warnings or errors only
#define INFINITECH_LOG_LEVEL 1
#endif
void infinitech_logError(const char *fmt, ...);
void infinitech_logWarn(const char *fmt, ...);
void infinitech_logInfo(const char *fmt, ...);
void infinitech_logDebug(const char *fmt, ...);
void infinitech_logTrace(const char *fmt, ...);

// Basic file I/O on C-string paths or where C-strings not needed
int infinitech_cwd(char *path, size_t *pathSize);
int infinitech_stat(const char *path, struct stat *statbuf);
int infinitech_removeOkWithStat(const char *path, const struct stat *statbuf);
int infinitech_removeOk(const char *path);
int infinitech_chdir(const char *path);
int infinitech_close(int *fid);
int infinitech_unlink(const char *path);
int infinitech_createForWrite(int *fid, const char *path, mode_t acl, char noOverwrite);
int infinitech_openForRead(int *fid, const char *path);
int infinitech_readData(int fid, u_int8_t *data, size_t count);
int infinitech_writeData(int fid, const u_int8_t *data, size_t count);
int infinitech_writeDataVector(int fid, const struct iovec *iov, int iovcnt, size_t totalBytes);
int infinitech_fstat(int fid, struct stat *statbuf);
int infinitech_mkdir(const char *path, mode_t acl);
int infinitech_mktmpDir(const char *parentDir, char *path, size_t *pathSize);
int infinitech_rmdir(const char *path);
int infinitech_rmdirPop(const char *path, int maxFids);
int infinitech_mkdirRelPush(const char *parentDir, const char *subpath, mode_t acl);
int infinitech_mkdirCwdPush(const char *subpath, mode_t acl);

// Memory related
void infinitech_zero(void *ptr, size_t size);
void *infinitech_hugePageAlloc(size_t pageCount, size_t pageSizeKb);
int infinitech_hugePageFree(void *ptr, size_t pageCount, size_t pageSizeKb);

// NUMA/CPU-affinity
int infinitech_pinCpu(int cpu);

// CURL
int infinitech_curlget(const char *url, void *context, infinitech_curl_callback cb);

// C-API for JSON processing wrapping simdjson, stringzilla. These routines naturally
// work in terms of ptr+length so StringRef based APIs not needed
void *infinitech_createJsonDoc();
void infinitech_destroyJsonDoc(void *handle);
int infinitech_resetJsonDoc(void *handle, const char *data, const size_t dataSize);
int infinitech_findJsonDocKeyValue(void *handle, const char *key, const size_t keyLength,
  struct StringRef *result);
int infinitech_findJsonDocNestedKeyValue(void *handle, const char *key, const size_t keyLength,
  struct StringRef *result);
int infinitech_stripJsonWhiteSpace(const char *data, const size_t dataSize, char *output, size_t *outputSize);
const char *infinitech_strstr(const char *data, const size_t dataSize, const char *key, const size_t keyLength);

#ifdef __cplusplus
};
#endif
