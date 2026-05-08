const std = @import("std");

fn work(cpu: u32) void {
  const one = @as(u64, 1);
  // const mask: u64 = 0xffffffffffffffff;
  const t: u6 = @truncate(cpu);
  const bit = one << t;

  std.debug.print("{d} << {d} = {d}\n", .{one, cpu, bit});
}

pub fn main() !void {
  for (0..255) |i| {
    work(@truncate(i));
  }
}
