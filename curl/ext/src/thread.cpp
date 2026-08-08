#include <binding.h>
#include <errno.h>
#include <fcntl.h>
#include <sched.h>
#include <errno.h>
#include <string.h>
#include <assert.h>
#include <pthread.h>

#ifdef __cplusplus
extern "C" {
#endif

int infinitech_pinCpu(int cpu) {
  assert(cpu>=0);
  cpu_set_t mask;
  CPU_ZERO(&mask);
  CPU_SET(cpu, &mask);
  int rc = 0;
  if (pthread_setaffinity_np(pthread_self(), sizeof(cpu_set_t), &mask) == -1) {
    rc = errno;
    infinitech_logError("could pin caller thread to cpu %d: %d (errno==%d)\n", cpu, strerror(rc), rc);
  } else {
    infinitech_logDebug("pinned caller thread to cpu %d\n", cpu);
  }
  return rc;
}

#ifdef __cplusplus
};
#endif
