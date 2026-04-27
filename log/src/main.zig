const std = @import("std");
const config = @import("config");

fn createLogStructType(comptime enabled: bool) type {
  if (enabled) {
    return struct {
      stdout: *std.Io.Writer,
      stderr: *std.Io.Writer,
      outWriter: std.Io.File.Writer,
      errWriter: std.Io.File.Writer,
      outBuffer: [4096]u8 = undefined,
      errBuffer: [4096]u8 = undefined,
      io: std.Io,
      bubba: i32 = 999,

      pub fn init(self: *@This(), io: std.Io) !void {
        self.io = io;
        self.outWriter = std.Io.File.stdout().writer(self.io, &self.outBuffer);
        self.errWriter = std.Io.File.stderr().writer(self.io, &self.errBuffer);
        self.stdout = &self.outWriter.interface;
        self.stderr = &self.errWriter.interface;
      }

      pub fn err(self: *@This(), comptime format: []const u8, args: anytype) !void {
        const now = std.Io.Clock.real.now(self.io).toNanoseconds();
        try self.stderr.print("error: {d}: ", .{now});
        try self.stderr.print(format, args);
        try self.stderr.flush();
      }  
    };
  } else {
    return struct {
      pub fn init(self: *@This(), io: std.Io) !void {
        _ = self;
        _ = io;
      }

      pub fn err(self: *@This(), comptime format: []const u8, args: anytype) !void {
        _ = self;
        _ = format;
        _ = args;
      }  
    };
  }
}

pub fn main(init: std.process.Init) !void {
  const logType = createLogStructType(config.logEnabled);
  var logger: logType = undefined;
  try logger.init(init.io);
  try logger.err("this is a test\n", .{});
}
