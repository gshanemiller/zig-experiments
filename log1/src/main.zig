const std = @import("std");
const me = @import("log1");

fn test1() void {
  std.debug.print("test1\n", .{});
  const logger: me.log.Log = .{};
  logger.err("err\n", .{});
  logger.warn("warn\n", .{});
  logger.info("info\n", .{});
  logger.debug("debug\n", .{});
  logger.trace("trace\n", .{});
  logger.stat("stat\n", .{});
  std.debug.print("level: {any}\n", .{logger.level()});
  std.debug.print("stats: {}\n", .{logger.statsEnabled()});
  logger.logLevel = me.log.Log.Level.OFF;
  std.debug.print("level: {any}\n", .{logger.level()});
  std.debug.print("stats: {}\n", .{logger.statsEnabled()});
}

pub fn main() !void {
  test1();
}
