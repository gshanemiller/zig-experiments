const std = @import("std");

// "Juicy Main" pattern: receive the 'init' object
pub fn main(init: std.process.Init) !void {
    const MyStruct = struct {
        id: u32,
        name: []const u8,
        is_active: bool = true,
    };

    // 1. Get the Io instance from 'init'
    const io = init.io;

    // 2. Create a buffered writer for stdout
    var stdout_buf: [1024]u8 = undefined;
    var stdout_file_writer: std.Io.File.Writer = .init(.stdout(), io, &stdout_buf);
    
    // 3. Obtain the pointer to the writer interface
    const stdout = &stdout_file_writer.interface;

    const info = @typeInfo(MyStruct);
    try stdout.writeAll("Struct Analysis (Zig 0.16.0):\n");

    inline for (info.@"struct".fields) |field| {
        try stdout.print("\nField: {s}\n", .{field.name});
        try stdout.print("  Type: {any}\n", .{field.type});
    }
    
    // 4. In 0.16.0, buffered writers must be explicitly flushed
    try stdout.flush();
}

