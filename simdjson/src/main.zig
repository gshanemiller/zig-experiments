const std = @import("std");
const binding_c = @import("binding_c");

pub fn main() !void {
  const key: []const u8 = "12";
  const data: []const u8 = "ab12";

  if (0==binding_c.infinitech_strstr(&data[0], data.len, &key[0], key.len)) {
    std.debug.print("find not found\n", .{});
  } else {
    std.debug.print("find found\n", .{});
  }

  if (binding_c.infinitech_createJsonDocument()) |hndl| {
    std.debug.print("good doc handle\n", .{});
    if (0!=binding_c.infinitech_resetJsonDocument(hndl, &data[0], data.len)) {
      std.debug.print("bad json\n", .{});
    } else {
      std.debug.print("good json\n", .{});
    }
  }
  return ;
}

