#include <stddef.h>
#include <json_binding.h>
#include <stdio.h>
#include <string.h>

int main(int argc, char **argv) {
  const char *data = "ab12";
  const char *key = "12";

  if (0==infinitech_strstr(data, strlen(data), key, strlen(key))) {
    printf("not found\n");
  } else {
    printf("found\n");
  }

  void *handle = infinitech_createJsonDocument();
  if (handle==0) {
    printf("bad handle\n");
    return 0;
  }
  if (0!=infinitech_resetJsonDocument(handle, data, strlen(data))) {
    printf("bad json\n");
  } else {
    printf("good json\n");
  }

  return 0;
}
