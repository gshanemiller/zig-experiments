const std = @import("std");
const task = @import("download_zip");

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
