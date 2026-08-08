#include <binding.h>
#include <ftw.h>
#include <stdio.h>
#include <fcntl.h>
#include <errno.h>
#include <unistd.h>
#include <stdlib.h>
#include <stdarg.h>
#include <assert.h>
#include <string.h>
#include <sys/uio.h>
#include <sys/stat.h>

#ifdef __cplusplus
extern "C" {
#endif

void infinitech_logError(const char *fmt, ...) {
  assert(fmt);
  assert(fmt[0]);
  fprintf(stderr, "error: ");
  va_list ap;
  va_start(ap, fmt);
  vfprintf(stderr, fmt, ap);
  va_end(ap);
}

#if INFINITECH_LOG_LEVEL>=1
void infinitech_logWarn(const char *fmt, ...) {
  assert(fmt);
  assert(fmt[0]);
  fprintf(stderr, "warn : ");
  va_list ap;
  va_start(ap, fmt);
  vfprintf(stderr, fmt, ap);
  va_end(ap);
}
#else
void infinitech_logWarn(const char *fmt, ...) {
}
#endif

#if INFINITECH_LOG_LEVEL>=2
void infinitech_logInfo(const char *fmt, ...) {
  assert(fmt);
  assert(fmt[0]);
  fprintf(stderr, "info : ");
  va_list ap;
  va_start(ap, fmt);
  vfprintf(stderr, fmt, ap);
  va_end(ap);
}
#else
void infinitech_logInfo(const char *fmt, ...) {
}
#endif

#if INFINITECH_LOG_LEVEL>=3
void infinitech_logDebug(const char *fmt, ...) {
  assert(fmt);
  assert(fmt[0]);
  fprintf(stderr, "debug: ");
  va_list ap;
  va_start(ap, fmt);
  vfprintf(stderr, fmt, ap);
  va_end(ap);
}
#else
void infinitech_logDebug(const char *fmt, ...) {
}
#endif

#if INFINITECH_LOG_LEVEL>=4
void infinitech_logTrace(const char *fmt, ...) {
  assert(fmt);
  assert(fmt[0]);
  fprintf(stderr, "trace: ");
  va_list ap;
  va_start(ap, fmt);
  vfprintf(stderr, fmt, ap);
  va_end(ap);
}
#else
void infinitech_logTrace(const char *fmt, ...) {
}
#endif

// Basic file I/O, operations on C string paths or which do not need C-string paths
int infinitech_cwd(char *path, size_t *pathSize) {
  assert(path);
  assert(pathSize);
  assert(*pathSize);
  int rc = 0;
  char *ptr = getcwd(path, *pathSize);
  if (0==ptr) {
    rc = errno;
    infinitech_logError("could not obtain process cwd with size limit %lu: %s (errno==%d)\n",
      *pathSize, strerror(rc), rc);
    path[0] = 0;
  } else {
    *pathSize = strlen(path);
    infinitech_logDebug("process cwd '%s' length %lu\n", path, *pathSize);
  }
  return rc;
}

int infinitech_stat(const char *path, struct stat *statbuf) {
  assert(path);
  assert(path[0]);
  assert(statbuf);

  int rc = 0;

  memset(statbuf, 0, sizeof(struct stat));
  if (0!=stat(path, statbuf)) {
    rc = errno;
    infinitech_logError("cannot stat '%s': %s (errno=%d)\n", path, strerror(rc), rc);
  } else {
    infinitech_logDebug("stat '%s' with %lu bytes uid %u gid %u\n",
      path, statbuf->st_size, statbuf->st_uid, statbuf->st_gid);
  }
  return rc;
}

int infinitech_removeOkWithStat(const char *path, const struct stat *statbuf) {
  assert(path);
  assert(path[0]);

  if (statbuf->st_uid==0 || getuid()!=statbuf->st_uid || geteuid()!=statbuf->st_uid) {
    infinitech_logError("removeOk denied on '%s' for caller uid %u eid %d file uid %u\n",
      path, getuid(), geteuid(), statbuf->st_uid);
    return EPERM;
  }

  infinitech_logDebug("removeOk '%s' for caller uid %u eid %d file uid %u\n",
    path, getuid(), geteuid(), statbuf->st_uid);

  return 0;
}

int infinitech_removeOk(const char *path) {
  assert(path);
  assert(path[0]);

  struct stat statbuf;
  memset(&statbuf, 0, sizeof(struct stat));
  if (0!=stat(path, &statbuf)) {
    int rc = errno;
    infinitech_logError("removeOk stat '%s' failed: %s (errno=%d)\n",
      path, strerror(rc), rc);
    return rc;
  }

  return infinitech_removeOkWithStat(path, &statbuf);
}

int infinitech_close(int *fid) {
  assert(fid);
  assert(*fid>=0);
  int rc = 0;
  if (close(*fid)!=0) {
    rc = errno;
    infinitech_logError("cannot close fid %d: %s (errno=%d)\n", *fid, strerror(rc), rc);
  } else {
    infinitech_logDebug("closed fid %d\n", *fid);
  }
  *fid = -1;
  return rc;
}

int infinitech_unlink(const char *path) {
  assert(path);
  assert(path[0]);

  int rc=0;
  if (0!=(rc=infinitech_removeOk(path))) {
    infinitech_logError("cannot remove '%s'. removeOk failed\n", path);
    return rc;
  }

  if (0!=unlink(path)) {
    rc = errno;
    infinitech_logError("cannot remove '%s': %s (errno==%d)\n", path, strerror(rc), rc);
  } else {
    infinitech_logDebug("unlink '%s'\n", path);
  }
  return rc;
}

int infinitech_createForWrite(int *fid, const char *path, mode_t acl, char noOverwrite) {
  assert(fid);
  assert(path);
  assert(path[0]);

  // Setup to create file
  if (acl==0) {
    acl = S_IRWXU;
  }
  int flags = O_CREAT|O_WRONLY|O_TRUNC;
  if (noOverwrite) {
    // open will fail if file already exists
    flags |= O_EXCL;
  }

  // Create file
  int rc = 0;
  int tmp = open(path, flags, acl);
  if (tmp==-1) {
    rc = errno;
    infinitech_logError("cannot create file '%s' for mode %d flags %d uid %d eid %u: %s (errno=%d)\n",
      path, acl, flags, getuid(), geteuid(), strerror(rc), rc);
  } else {
    *fid = tmp;
    infinitech_logDebug("created file '%s' fid %d mode %d flags %d uid %d eid %u\n",
      path, *fid, acl, flags, getuid(), geteuid());
  }
  return rc;
}

int infinitech_openForRead(int *fid, const char *path) {
  assert(fid);
  assert(path);
  assert(path[0]);

  int rc = 0;

  *fid = open(path, O_RDONLY);
  if (*fid==-1) {
    rc = errno;
    infinitech_logError("cannot open '%s' for read uid %d eid %u: %s (errno=%d)\n",
      path, getuid(), geteuid(), strerror(rc), rc);
  } else {
    infinitech_logDebug("opened '%s' fid=%d uid %d eid %d for read\n",
      path, *fid, getuid(), geteuid());
  }
  return rc;
}

int infinitech_readData(int fid, u_int8_t *data, size_t count) {
  assert(fid>=0);
  assert(data);
  assert(count);
  int rc = 0;
  size_t bytes = read(fid, data, count);
  if (bytes!=count) {
    rc = errno;
    infinitech_logError("read only %lu of requested %lu bytes from fid %d: %s (errno=%d)\n",
      bytes, count, fid, strerror(rc), rc);
  } else {
    infinitech_logTrace("read %lu bytes from fid %d\n", bytes, fid);
  }
  return rc;
}

int infinitech_writeData(int fid, const u_int8_t *data, size_t count) {
  assert(fid>=0);
  assert(data);
  assert(count);
  int rc = 0;
  size_t bytes = write(fid, data, count);
  if (bytes!=count) {
    rc = errno;
    infinitech_logError("wrote only %lu of requested %lu bytes to fid %d: %s (errno=%d)\n",
      bytes, count, fid, strerror(rc), rc);
  } else {
    infinitech_logTrace("wrote %lu bytes to fid %d\n", bytes, fid);
  }
  return rc;
}

int infinitech_writeDataVector(int fid, const struct iovec *iov, int iovcnt, size_t totalBytes) {
  assert(fid>=0);
  assert(iov);
  assert(iovcnt);
#ifndef NDEBUG
  size_t tmpTotal = 0;
  for (int i=0; i<iovcnt; ++i) {
    assert(iov[i].iov_base);
    assert(iov[i].iov_len);
    tmpTotal += iov[i].iov_len;
  }
  assert(tmpTotal==totalBytes);
#endif
  int rc = 0;
  size_t actualBytes = writev(fid, iov, iovcnt);
  if (actualBytes!=totalBytes) {
    rc = errno;
    infinitech_logError("wrotev only %lu of requested %lu bytes to fid %d: %s (errno=%d)\n",
      actualBytes, totalBytes, fid, strerror(rc), rc);
  } else {
    infinitech_logTrace("wrotev %lu bytes to fid %d\n", totalBytes, fid);
  }
  return rc;
}

int infinitech_fstat(int fid, struct stat *statbuf) {
  assert(fid>=0);
  assert(statbuf);

  int rc = 0;

  memset(statbuf, 0, sizeof(struct stat));
  if (fstat(fid, statbuf)!=0) {
    rc = errno;
    infinitech_logError("cannot fstat fid %d: %s (errno=%d)\n", fid, strerror(rc), rc);
  } else {
    infinitech_logDebug("fstat fid %d with %lu bytes uid %u gid %u\n",
      fid, statbuf->st_size, statbuf->st_uid, statbuf->st_gid);
  }
  return rc;
}

int infinitech_chdir(const char *path) {
  assert(path);
  assert(path[0]);

  int rc = 0;
  if (0!=chdir(path)) {
    rc = errno;
    infinitech_logError("cannot chdir '%s': %s (errno=%d)\n",
      path, strerror(rc), rc);
  } else {
    infinitech_logDebug("chdir '%s'\n", path);
  }
  return rc;
}

int infinitech_mkdir(const char *path, mode_t acl) {
  assert(path);
  assert(path[0]);

  int rc = 0;
  if (acl==0) {
    acl = S_IRWXU;
  }
  if (0!=mkdir(path, acl)) {
    rc = errno;
    infinitech_logError("could not mkdir '%s' acl %d uid %u eid %u: %s (errno=%d)\n",
      path, acl, getuid(), geteuid(), strerror(rc), rc);
  } else {
    infinitech_logDebug("mkdir '%s' acl %d uid %u eid %u\n",
      path, acl, getuid(), geteuid());
  }
  return rc;
}

int infinitech_mktmpDir(const char *parentDir, char *path, size_t *pathSize) {
  assert(parentDir);
  assert(path);
  assert(pathSize);
  assert(*pathSize);

  if ((strlen(parentDir)+INFINITECH_TMPDIR_SUFFIX_SIZE)>*pathSize) {
    infinitech_logError("cannot make tmpdir in '%s': pathSize too small\n", parentDir);
    return ENOMEM;
  }

  int rc = 0;
  *pathSize = snprintf(path, *pathSize, "%s/tmpXXXXXX", parentDir);
  if (0==mkdtemp(path)) {
    rc = errno;
    path[0]=0;
    infinitech_logError("cannot make tmpdir for uid %d eid %d in '%s': %s (errno==%d)\n",
      getuid(), geteuid(), parentDir, strerror(rc), rc);
  } else {
    infinitech_logDebug("created tmpDir '%s' for uid %d eid %d\n",
      path, getuid(), geteuid());
  }
  return rc;
}

int infinitech_rmdir(const char *path) {
  assert(path);
  assert(path[0]);

  int rc = 0;

  if (0!=(rc=infinitech_removeOk(path))) {
    infinitech_logError("cannot rmdir '%s': removeOk failed\n", path);
    return rc;
  }

  if (0!=rmdir(path)) {
    rc = errno;
    infinitech_logError("cannot rmdir '%s': %s (errno==%d)\n",
      path, strerror(rc), rc);
  } else {
    infinitech_logDebug("rmdir '%s'\n", path);
  }
  return rc;
}

static int infinitech_removeFileObj(const char *fpath, const struct stat *sb,
  int typeflag, struct FTW *ftwbuf) {
  assert(fpath);
  assert(fpath[0]);
  assert(sb);
  assert(ftwbuf);

  int rc = 0;

  if (0!=(rc=infinitech_removeOkWithStat(fpath, sb))) {
    infinitech_logDebug("abort rmdirPop: rmdir '%s' denied by removeOk\n", fpath);
    return rc;
  }

  if (typeflag == FTW_DP) {
    if (0!=rmdir(fpath)) {
      rc = errno;
      infinitech_logError("abort rmdirPop: rmdir '%s' failed: %s (errno==%d)\n",
        fpath, strerror(rc), rc);
    } else {
      infinitech_logDebug("rmdirPop: rmdir '%s'\n", fpath);
    }
  } else {
    if (0!=unlink(fpath)) {
      rc = errno;
      infinitech_logError("abort rmdirPop: unlink '%s' failed: %s (errno==%d)\n",
        fpath, strerror(rc), rc);
    } else {
      infinitech_logDebug("rmdirPop: unlink '%s'\n", fpath);
    }
  }
  return rc;
}

int infinitech_rmdirPop(const char *parentDir, int maxFids) {
  assert(parentDir);
  assert(parentDir[0]);
  assert(maxFids>0);

  infinitech_logWarn("recursive rm '%s' requested\n", parentDir);

  int flags = FTW_DEPTH | FTW_PHYS;
  int rc = nftw(parentDir, infinitech_removeFileObj, maxFids, flags);

  if (rc!=0) {
    infinitech_logError("recursive rm '%s' failed\n", parentDir);
  } else {
    infinitech_logDebug("recursive rm '%s' done\n", parentDir);
  }

  return rc;
}

int infinitech_mkdirRelPush(const char *parentDir, const char *subpath, mode_t acl) {
  assert(parentDir);
  assert(parentDir[0]);
  assert(subpath);
  assert(subpath[0]!='/');

  if (acl==0) {
    acl = S_IRWXU;
  }

  if (strlen(subpath)>INFINITECH_MAXIMUM_PATH_LENGTH) {
    infinitech_logError("could not mkdirRelPush '%s' acl %d in parentDir '%s': subpath too long\n",
      subpath, acl, parentDir);
    return ENOMEM;
  }

  int rc = 0;
  if (0!=(rc=infinitech_chdir(parentDir))) {
    infinitech_logError("could not mkdirRelPush '%s' acl %d in parentDir '%s': chdir parentDir failed\n",
      subpath, acl, parentDir);
    return rc;
  }

  char tmp[INFINITECH_MAXIMUM_PATH_SIZE]={0};
  strcpy(tmp, subpath);

  const char *delimiter = "/";
  for(char *dir=strtok(tmp, delimiter); dir; dir=strtok(0, delimiter)) {
    // if the directory already exists and can chdir into just do that
    if (0==(rc=infinitech_chdir(dir))) {
      infinitech_logDebug("mkdirRelPush '%s' acl %d in parentDir '%s' uid %d eid %d dir '%s' exists\n",
        subpath, acl, parentDir, getuid(), geteuid(), dir);
      continue;
    }
    if (0!=mkdir(dir, acl)) {
      rc = errno;
      infinitech_logError("could not mkdirRelPush '%s' acl %d in parentDir '%s' uid %d eid %d for dir '%s': %s (errno=%d)\n",
        subpath, acl, parentDir, getuid(), geteuid(), dir, strerror(rc), rc);
      return rc;
    }
    if (0!=(rc=infinitech_chdir(dir))) {
      infinitech_logError("could not mkdirRelPush '%s' acl %d in parentDir '%s'. chdir failed\n",
        subpath, acl, parentDir);
      return rc;
    }
  }
  infinitech_logDebug("mkdirRelPush '%s' acl %d in parentDir '%s' uid %u eid %u\n",
    subpath, acl, parentDir, getuid(), geteuid());
  return rc;
}

int infinitech_mkdirCwdPush(const char *subpath, mode_t acl) {
  assert(subpath);
  assert(subpath[0]!='/');

  int rc=0;
  size_t len = INFINITECH_MAXIMUM_PATH_SIZE;
  char cwd[INFINITECH_MAXIMUM_PATH_SIZE]={0};

  if (0!=(rc=infinitech_cwd(cwd, &len))) {
    infinitech_logError("could not mkdirCwdPush subpath '%s' acl %d. unable to determine cwd\n",
      subpath, acl);
    return rc;
  }
  return infinitech_mkdirRelPush(cwd, subpath, acl);
}

#ifdef __cplusplus
};
#endif
