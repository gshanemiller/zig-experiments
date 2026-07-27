const std = @import("std");
const Io = std.Io;

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const allocator = init.arena.allocator();

    // Initialize the CLI argument iterator from init context
    var args = try init.minimal.args.iterateAllocator(allocator);

    // Skip the executable name (argv[0])
    _ = args.skip();

    // Fetch the target zip file path
    const zip_path = args.next() orelse {
        std.debug.print("Usage: unzip <file.zip>\n", .{});
        return;
    };

    // Open the zip file using the mandatory 0.16.0 I/O engine context
    const file = try Io.Dir.cwd().openFile(io, zip_path, .{ .mode = .read_only });
    defer file.close(io);

    // Get a seekable stream bound to the I/O interface
    const seekable_stream = file.seekableStream(io);

    // Extract the archive contents into the current working directory
    // Note: extraction routines in 0.16.0 accept the I/O context
    try std.zip.extract(io, Io.Dir.cwd(), seekable_stream, .{});

    std.debug.print("Successfully extracted: {s}\n", .{zip_path});
}
