const std = @import("std");
const Io = std.Io;

fn makeType() type {
  return extern struct {
    d_senderId:    u64 align(1),
    d_senderMsgId: u64 align(1),
    d_data       : u64 align(1), 

    fn privateMethod(self: *@This(), value: u64) void {
      self.d_data = value;
    }

    pub fn publicMethod(self: *@This(), tag: []const u8, v1: u16, v2: u32, v3: u64) i32 {
      _ = self;
      std.debug.print("{s} v1={d} v2={d} v3={d}\n", .{tag, v1, v2, v3});
      return 63;
    }

    pub fn publicMethod1(self: *@This(), tag: []const u8, v1: u16, v2: u32, v3: u64) void {
      _ = self;
      _ = tag;
      std.debug.print("{s} v1={d} v2={d} v3={d}\n", .{v1, v2, v3});
    }
  };
}

fn printTypeFields() void {
    const T = makeType();
    const info = @typeInfo(T);

    inline for (info.@"struct".decls) |decl| {
        // We use @TypeOf to get the type of the declaration
        const DeclType = @TypeOf(@field(T, decl.name));
        const decl_info = @typeInfo(DeclType);

        // Switch on the type info union
        switch (decl_info) {
            // Use the .@"fn" or .fn tag to identify functions
            .@"fn" => |func| {
                std.debug.print("fn {s}(", .{decl.name});

                // Iterate through parameters
                inline for (func.params, 0..) |param, i| {
                    if (param.type) |p_t| {
                        std.debug.print("{s}", .{@typeName(p_t)});
                    } else {
                        std.debug.print("anytype", .{});
                    }
                    if (i < func.params.len - 1) std.debug.print(", ", .{});
                }

                // Get return type
                const ret = func.return_type orelse void;
                std.debug.print(") {s}\n", .{@typeName(ret)});
            },
            // Handle other declaration types (constants, types, etc.) by doing nothing
            else => {},
        }
    }
}

pub fn main() !void {
  printTypeFields();
}
