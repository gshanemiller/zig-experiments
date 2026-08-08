const std = @import("std");

static size_t curlCallback(void *data, size_t size, size_t nmemb, void *userp) {                                        

export fn curlCallback(data: anyopaque, size: u64, nmemb: u64, context: anyopaque) callconv(.C) u64 {
  std.debug.print("zig curlCallback got data {*} size {} nmemb {} context {*}\n",
    .{data, size, nmemb, context});
  return size*nmemb;
}

pub fn main() !void {
}
