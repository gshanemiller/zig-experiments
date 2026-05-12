const std = @import("std");

const Stuff = struct {
  allocator: ?*anyopaque,

  pub fn init(self: *@This()) void {
    _ = self;
  }
};

pub fn main() !void {
  var stuff: Stuff = undefined;
  stuff.init();
  std.debug.print("{any}\n", .{stuff});
}
