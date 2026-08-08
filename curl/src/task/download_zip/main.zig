const std = @import("std");
const task = @import("download_zip");

// To make curl's data writer function callback work with ZIG while avoiding curl's
// void* for // 'rawData', and user context 'rawContext' arguments --- which are fine
// in and of themselves, but they hit into ZIG's pickiness about treating C void* 
// like ?*anyopaque which I could make work --- I specified u64 which occupies as
// much space on the stack as a pointer. Then I cast to what I need for ZIG. And,
// indeed, C-code would do casts granted in a less opaque way.

// Using CURL instead of std.http.Client, which I tried first, is a work around
// for some ZIG library wierdness. http.Client downloads the first URL as expected.
// However, for reasons I cannot work out, the second URL (golden-copy.json.zip)
// does not. The first 100 bytes are just completely wrong (likely all bytes 
// wrong). Maybe encoding/blocking or something else? CURL however works for both
// delivering bytes as expected when compared to running CURL or wget in bash.
export fn curlCallback(rawData: usize, size: u64, nmemb: u64, rawContext: usize) callconv(.c) u64 {
  std.debug.assert(rawData!=0);
  std.debug.assert(size==1);
  std.debug.assert(rawContext!=0);

  var obj: *TestCurl = @ptrFromInt(rawContext);

  if (obj.total==0) {
    var slice: []u8 = "";
    slice.ptr = @ptrFromInt(rawData);
    slice.len = nmemb;
    std.debug.print("first 100 bytes: {x}\n", .{slice[0..100]});
  }
  obj.total = obj.total + nmemb;
  return nmemb;
}

const TestCurl = struct {
  total: u64,

  pub fn download(self: *@This()) void {
    self.total = 0;
    // const url = "https://github.com/temporalio/cli/releases/download/v1.8.1/temporal_cli_1.8.1_windows_arm64.zip";
    const url = "https://leidata-preview.gleif.org/storage/golden-copy-files/2026/06/23/1242737/20260623-1600-gleif-goldencopy-lei2-golden-copy.json.zip";
    std.debug.print("self {*}\n", .{self});
    const rc = task.c.infinitech_curlget(url.ptr, self, curlCallback);                                    
    std.debug.print("download complete rc {} total {}\n", .{rc, self.total});
  }
};

pub fn main() !u8 {
  var curl: TestCurl = .{.total = 0};
  curl.download();
  return 0;
}
