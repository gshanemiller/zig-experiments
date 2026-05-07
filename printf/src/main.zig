const std = @import("std");
const Io = std.Io;

pub fn main() !void {
  const addr: u32 = 0xff312301;
  const port: u16 = 32131;
  const vlanId: u16 = 2331;
  const mac: [6]u8 = .{10,11,12,13,14,1};

  var foo: [62]u8 = undefined;

  const junk = try std.fmt.bufPrint(&foo, "ether={x:0>2}:{x:0>2}:{x:0>2}:{x:0>2}:{x:0>2}:{x:0>2} ipv4:{d:0>3}.{d:0>3}.{d:0>3}.{d:0>3}:{d:0>5} vlanId={d:0>4}", .{
      mac[0],
      mac[1],
      mac[2],
      mac[3],
      mac[4],
      mac[5],
      (addr & 0xff),
      ((addr>>8) & 0xff),
      ((addr>>16) & 0xff),
      ((addr>>24) & 0xff),
      port,
      vlanId
    });

  std.debug.print("{s}\n", .{foo});
  std.debug.print("{s}\n", .{junk});
  std.debug.print("{d}\n", .{foo.len});
  std.debug.print("{d}\n", .{junk.len});
}
