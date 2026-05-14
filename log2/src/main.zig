const std = @import("std");
const me = @import("log2");

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
}

fn test2() void {
  std.debug.print("test2\n", .{});
  me.log.AppLog.err("err\n", .{});
  me.log.AppLog.warn("warn\n", .{});
  me.log.AppLog.info("info\n", .{});
  me.log.AppLog.debug("debug\n", .{});
  me.log.AppLog.trace("trace\n", .{});
  me.log.AppLog.stat("stat\n", .{});
  std.debug.print("level: {any}\n", .{me.log.AppLog.level()});
  std.debug.print("stats: {}\n", .{me.log.AppLog.statsEnabled()});
}

pub fn main() !void {
  test1();
  test2();
}
