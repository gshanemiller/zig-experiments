const std = @import("std");
const me = @import("log1");

pub fn main() !void {
  me.applog.info("hello world\n", .{});
}
