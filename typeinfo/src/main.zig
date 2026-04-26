const std = @import("std");

const Test = struct {
  b1: u32,
  b2: []const u8,
};

pub fn main() !void {
    const my_var: i32 = 42;

    // 2. Get type information
    const info = @typeInfo(@TypeOf(my_var));
    // 3. Print to stdout (requires 'try' or error handling)
    std.debug.print("Type Info: {any}\n", .{info});
}
