#include <binding.h>
#include <assert.h>
#include <curl/curl.h>

#ifdef __cplusplus
extern "C" {
#endif

int infinitech_curlget(const char *url, void *context, infinitech_curl_callback cb) {
  assert(url);
  assert(url[0]);

  CURLcode res;
  CURL *curl_handle;

  // Initialize the libcurl global state
  curl_global_init(CURL_GLOBAL_DEFAULT);

  // Initialize an easy session handle
  curl_handle = curl_easy_init();
  if(curl_handle) {
    // Pass the target URL
    curl_easy_setopt(curl_handle, CURLOPT_URL, url);

    // Define our data write callback function
    curl_easy_setopt(curl_handle, CURLOPT_WRITEFUNCTION, cb);

    // Pass our custom struct pointer to the callback function
    curl_easy_setopt(curl_handle, CURLOPT_WRITEDATA, context);

    // Provide a User-Agent string to satisfy servers that mandate it
    curl_easy_setopt(curl_handle, CURLOPT_USERAGENT, "libcurl-agent/1.0");

    // 1. Enable automatic redirect following
    curl_easy_setopt(curl_handle, CURLOPT_FOLLOWLOCATION, 1L);

    // 2. Prevent infinite loops by capping redirect hops
    curl_easy_setopt(curl_handle, CURLOPT_MAXREDIRS, 10L);

    // 3. Force libcurl to maintain POST on 302 redirects (instead of switching to GET)
    curl_easy_setopt(curl_handle, CURLOPT_POSTREDIR, CURL_REDIR_POST_302);

    // Execute the synchronous network transfer
    res = curl_easy_perform(curl_handle);

    // Check for transfer errors
    if(res != CURLE_OK) {
      infinitech_logError("curl failed: %s\n", curl_easy_strerror(res));
      return 1;
    }

    // Clean up session handle
    curl_easy_cleanup(curl_handle);
  }

  // Global cleanup
  curl_global_cleanup();

  return 0;
}

#ifdef __cplusplus
};
#endif
