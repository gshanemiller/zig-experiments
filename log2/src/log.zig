const std = @import("std");
const config = @import("config");

pub const AppLog: Log = .{};

pub const Log = struct {
  // Log levels
  pub const Level = enum(u8) {
    OFF,
    FATAL,
    ERROR,
    WARN,
    INFO,
    DEBUG,
    TRACE,
  };

  stats: bool = config.stats,
  logLevel: Level = @as(Level, @enumFromInt(@intFromEnum(config.logLevel))),

  /// Log specified 'format, args' then panic
  pub fn fatal(self: Log, comptime format: []const u8, args: anytype) void {
    _ = self;
    std.debug.panic(format, args);
  }

  /// Log specified 'format, args' provided 'level>=ERROR' else do nothing
  pub fn err(self: Log, comptime format: []const u8, args: anytype) void {
    if (@intFromEnum(self.logLevel)>=@intFromEnum(Level.ERROR)) {
      std.debug.print("error: ", .{});
      std.debug.print(format, args);
    }
  }

  /// Log specified 'format, args' provided 'level>=WARN' else do nothing
  pub fn warn(self: Log, comptime format: []const u8, args: anytype) void {
    if (@intFromEnum(self.logLevel)>=@intFromEnum(Level.WARN)) {
      std.debug.print("warn:  ", .{});
      std.debug.print(format, args);
    }
  }

  /// Log specified 'format, args' provided 'level>=INFO' else do nothing
  pub fn info(self: Log, comptime format: []const u8, args: anytype) void {
    if (@intFromEnum(self.logLevel)>=@intFromEnum(Level.INFO)) {
      std.debug.print("info:  ", .{});
      std.debug.print(format, args);
    }
  }

  /// Log specified 'format, args' provided 'level>=DEBUG' else do nothing
  pub fn debug(self: Log, comptime format: []const u8, args: anytype) void {
    if (@intFromEnum(self.logLevel)>=@intFromEnum(Level.DEBUG)) {
      std.debug.print("debug: ", .{});
      std.debug.print(format, args);
    }
  }

  /// Log specified 'format, args' provided 'level=TRACE' else do nothing
  pub fn trace(self: Log, comptime format: []const u8, args: anytype) void {
    if (@intFromEnum(self.logLevel)==@intFromEnum(Level.TRACE)) {
      std.debug.print("trace: ", .{});
      std.debug.print(format, args);
    }
  }

  /// Log specified 'format, args' provided 'logLevel.stats==true' else do nothing
  pub fn stat(self: Log, comptime format: []const u8, args: anytype) void {
    if (self.stats) {
      std.debug.print("stats: ", .{});
      std.debug.print(format, args);
    }
  }

  pub fn level(self: Log) Level {
    return self.logLevel;
  }

  pub fn statsEnabled(self: Log) bool {
    return self.stats;
  }
};
