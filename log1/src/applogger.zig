const log = @import("log.zig");

pub const AppLogger = struct {
  logger: log.Log.createType(log.Level.TRACE, true) = .{},
};
