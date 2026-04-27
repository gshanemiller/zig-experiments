const std = @import("std");
const config = @import("config");

fn createLogStructType(comptime enabled: bool, comptime statsEnabled: bool) type {
  if (enabled and statsEnabled) {
    return struct {
      stdout: *std.Io.Writer,
      writer: std.Io.File.Writer,
      buffer: [4096]u8 = undefined,
      io: std.Io,

      pub fn init(self: *@This(), io: std.Io) !void {
        self.io = io;
        self.writer = std.Io.File.stdout().writer(self.io, &self.buffer);
        self.stdout = &self.writer.interface;
      }

      pub fn debug(self: *@This(), comptime format: []const u8, args: anytype) !void {
        const now = std.Io.Clock.real.now(self.io).toNanoseconds();
        try self.stdout.print("debug: {d}: ",  .{now});
        try self.stdout.print(format, args);
        try self.stdout.flush();
      }  

      pub fn stat(self: *@This(), comptime format: []const u8, args: anytype) !void {
        const now = std.Io.Clock.real.now(self.io).toNanoseconds();
        try self.stdout.print("stat : {d}: ",  .{now});
        try self.stdout.print(format, args);
        try self.stdout.flush();
      }
    };
  } else if (enabled and !statsEnabled) {
    return struct {
      stdout: *std.Io.Writer,
      writer: std.Io.File.Writer,
      buffer: [4096]u8 = undefined,
      io: std.Io,

      pub fn init(self: *@This(), io: std.Io) !void {
        self.io = io;
        self.writer = std.Io.File.stdout().writer(self.io, &self.buffer);
        self.stdout = &self.writer.interface;
      }

      pub fn debug(self: *@This(), comptime format: []const u8, args: anytype) !void {
        const now = std.Io.Clock.real.now(self.io).toNanoseconds();
        try self.stdout.print("debug: {d}: ",  .{now});
        try self.stdout.print(format, args);
        try self.stdout.flush();
      }  

      pub fn stat(self: *@This(), comptime format: []const u8, args: anytype) !void {
        _ = self;
        _ = format;
        _ = args;
      }
    };
  } else {
    return struct {
      pub fn init(self: *@This(), io: std.Io) !void {
        _ = self;
        _ = io;
      }

      pub fn debug(self: *@This(), comptime format: []const u8, args: anytype) !void {
        _ = self;
        _ = format;
        _ = args;
      }  

      pub fn stat(self: *@This(), comptime format: []const u8, args: anytype) !void {
        _ = self;
        _ = format;
        _ = args;
      }  
    };
  }
}

pub fn main(init: std.process.Init) !void {
  const logType = createLogStructType(config.logEnabled, config.logStat);
  var logger: logType = undefined;
  try logger.init(init.io);
  try logger.debug("debug test\n", .{});
  try logger.stat("stat test\n", .{});
}
