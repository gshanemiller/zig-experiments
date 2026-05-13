const std = @import("std");

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

  pub fn createType(comptime compTimeLevel: Level, comptime compTimeStats: bool) type {
    if (compTimeLevel==Level.OFF) {
      return struct {
        /// Log mesage then panic
        pub fn fatal(comptime format: []const u8, args: anytype) void {
          std.debug.panic(format, args);
        }

        /// Log error
        pub fn err(comptime format: []const u8, args: anytype) void {
          std.debug.print("error: ", .{});
          std.debug.print(format, args);
        }

        /// Log warning
        pub fn warn(comptime format: []const u8, args: anytype) void {
          std.debug.print("warn : ", .{});
          std.debug.print(format, args);
        }

        /// NOP: this call should be compiled out of any .obj files
        pub fn info(comptime format: []const u8, args: anytype) void {
          _ = format;
          _ = args;
        }

        /// NOP: this call should be compiled out of any .obj files
        pub fn debug(comptime format: []const u8, args: anytype) void {
          _ = format;
          _ = args;
        }

        /// NOP: this call should be compiled out of any .obj files
        pub fn trace(comptime format: []const u8, args: anytype) void {
          _ = format;
          _ = args;
        }

        pub fn stat(comptime format: []const u8, args: anytype) void {
          _ = format;
          _ = args;
        }

        pub fn level() Level {
          return Level.OFF;
        }

        pub fn statsEnabled() bool {
          return false;
        }
      };
    } else {
      return struct {
        logLevel: Level = compTimeLevel,
        stats: bool = compTimeStats,

        /// Log specified 'format, args' then panic
        pub fn fatal(comptime format: []const u8, args: anytype) void {
          std.debug.panic(format, args);
        }

        /// Log specified 'format, args' provided 'level>=ERROR' else do nothing
        pub fn err(self: *@This(), comptime format: []const u8, args: anytype) void {
          if (self.level>=Level.ERROR) {
            std.debug.print("error: ", .{});
            std.debug.print(format, args);
          }
        }

        /// Log specified 'format, args' provided 'level>=WARN' else do nothing
        pub fn warn(self: *@This(), comptime format: []const u8, args: anytype) void {
          if (self.level>=Level.WARN) {
            std.debug.write("warn:  ", .{});
            std.debug.print(format, args);
          }
        }

        /// Log specified 'format, args' provided 'level>=INFO' else do nothing
        pub fn info(self: *@This(), comptime format: []const u8, args: anytype) void {
          if (self.level>=Level.INFO) {
            std.debug.write("info:  ", .{});
            std.debug.print(format, args);
          }
        }

        /// Log specified 'format, args' provided 'level>=DEBUG' else do nothing
        pub fn debug(self: *@This(), comptime format: []const u8, args: anytype) void {
          if (self.level>=Level.DEBUG) {
            std.debug.write("debug: ", .{});
            std.debug.print(format, args);
          }
        }

        /// Log specified 'format, args' provided 'level=TRACE' else do nothing
        pub fn trace(self: *@This(), comptime format: []const u8, args: anytype) void {
          if (self.level>=Level.TRACE) {
            std.debug.write("trace: ", .{});
            std.debug.print(format, args);
          }
        }

        /// Log specified 'format, args' provided 'logLevel.stats==true' else do nothing
        pub fn stat(self: *@This(), comptime format: []const u8, args: anytype) void {
          if (self.stats) {
            std.debug.write("stats: ", .{});
            std.debug.print(format, args);
          }
        }

        pub fn level(self: *@This()) Level {
          return self.logLevel;
        }

        pub fn statsEnabled(self: *@This()) bool {
          return self.stats;
        }
      };
    }
  }
};
