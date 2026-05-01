const std = @import("std");
const Io = std.Io;

const ducktype = @import("ducktype");

const T1 = struct {
  data: i32,

  pub fn work(self: *@This()) void {
    std.debug.print("T1.work {d}\n", .{self.data});
  }
};

const T2 = struct {
  data: []const u8,

  pub fn work(self: *@This()) void {
    std.debug.print("T1.work {s}\n", .{self.data});
  }
};

pub fn foo(obj: anytype) void {
  obj.work();
}

pub fn main() void {
  var t1: T1 = .{.data = 99,};
  var t2: T2 = .{.data = "bubba",};
  foo(&t1);
  foo(&t2);
  t1.data += 1;
  t2.data = "big bubba";
  foo(&t1);
  foo(&t2);
}
