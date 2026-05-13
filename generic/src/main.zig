const std = @import("std");

fn createType(comptime T: type) type {
  return struct {
    value: T,
    pub fn print(self: *@This()) void {
      std.debug.print("printing '{any}'\n", .{self.value});
    }
  };
}

pub fn stuff(data: anytype) void {
  data.print();
}

pub fn main() !void {
  const MyType = createType(u32);
  var data: MyType = undefined;
  data.value = 100;
  std.debug.print("type: '{s}'\n", .{@typeName(MyType)});
  stuff(&data);
}
