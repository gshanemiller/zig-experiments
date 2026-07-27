const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const gpa = init.gpa;
    const io = init.io;

    var client: std.http.Client = .{
        .allocator = gpa,
        .io = io,
    };
    defer client.deinit();

    const uri = try std.Uri.parse("https://github.com/temporalio/cli/releases/download/v1.8.1/temporal_cli_1.8.1_windows_arm64.zip");
    var req = try client.request(.GET, uri, .{});
    defer req.deinit();

    try req.sendBodiless();

    var bufHdr: [2048]u8 = undefined;
    var response = try req.receiveHead(&bufHdr);

    if (response.head.status != .ok) {
        std.debug.print("Failed: status {s}\n", .{response.head.status.phrase() orelse "unknown"});
        return;
    }

    var shaBuf: [std.crypto.hash.sha2.Sha256.digest_length]u8 = undefined;                                                
    var hasher: std.crypto.hash.sha2.Sha256 = .init(.{});

    var total: usize = 0;
    var dataHdr: [16384]u8 = undefined;
    var reader = response.reader(&dataHdr);

    while (true) {
        if (reader.peek(dataHdr.len)) |data| { 
          total = total + data.len;
          hasher.update(data); 
          reader.toss(data.len);
          // std.debug.print("data {x}\n", .{data});
          std.debug.print("total {}\n", .{total});
        } else |err| {
          std.debug.print("peek {} end {} seek {}\n", .{err, reader.end, reader.seek});
          break;
        }
    }
  
    if (reader.end>0) {
      total = total + reader.end;
      hasher.update(reader.buffer[0..reader.end]); 
    }

    hasher.final(&shaBuf);

    std.debug.print("end total {} end {} seek {}\n", .{total, reader.end, reader.seek});
    std.debug.print("SHA-256: {s}\n", .{std.fmt.bytesToHex(shaBuf, .lower)});                                             
}

