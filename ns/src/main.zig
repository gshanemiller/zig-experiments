const std = @import("std");

pub fn main() !void {
  var bs: std.posix.timespec = undefined;

  var a = std.Io.Threaded.nanosecondsFromPosix(&bs);
  std.debug.print("ns {any} {any}\n", .{bs, a});

  a = std.Io.Threaded.nanosecondsFromPosix(&bs);
  std.debug.print("ns {any} {any}\n", .{bs, a});

  a = std.Io.Threaded.nanosecondsFromPosix(&bs);
  std.debug.print("ns {any} {any}\n", .{bs, a});

  a = std.Io.Threaded.nanosecondsFromPosix(&bs);
  std.debug.print("ns {any} {any}\n", .{bs, a});
}
