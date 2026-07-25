const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const allocator = init.arena.allocator();
    var client: std.http.Client = .{
        .io = init.io,
        .allocator = allocator,
    };
    defer client.deinit();

    // const url = "https://leidata-preview.gleif.org/storage/golden-copy-files/2026/06/23/1242737/20260623-1600-gleif-goldencopy-lei2-golden-copy.json.zip";
    const url = "https://example.com";
    
    // Allocate buffer for redirect tracking
    var redirect_buffer: [4096]u8 = undefined;
    
    // Use allocating writer to capture the downloaded payload
    var body_writer: std.Io.Writer.Allocating = .init(allocator);
    defer body_writer.deinit();

    std.debug.print("Downloading from {s}...\n", .{url});

    _ = try client.fetch(.{
        .location = .{ .url = url },
        .method = .GET,
        .redirect_buffer = &redirect_buffer,
        .response_writer = &body_writer.writer,
    });

    const downloaded_data = body_writer.written();

    // Save data to a local file
    var file = try std.Io.Dir.createFileAbsolute(init.io, "/tmp/test.txt", .{});
    defer file.close(init.io);
    
    var write_buf: [8 * 1024]u8 = undefined;
    var file_writer = file.writer(init.io, &write_buf);
    try file_writer.interface.writeAll(downloaded_data);

    std.debug.print("Download complete! Saved {d} bytes.\n", .{downloaded_data.len});
}

