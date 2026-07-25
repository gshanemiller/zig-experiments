const std = @import("std");

pub fn main() void {
  const testData = "try std.testing.expectEqual(0, os.infinitech_readData(fid, &buffer, bytes));\n";                    
  const expectedHash = "93025269de1b6b1e5f90e739a46c993975cb33acb068ebbde9ca0adf37853e0a\x00";                          

  var buffer: [std.crypto.hash.sha2.Sha256.digest_length]u8 = undefined;
  std.crypto.hash.sha2.Sha256.hash(testData, &buffer, .{});
  std.debug.print("SHA-256: {s}\n", .{std.fmt.bytesToHex(buffer, .lower)});
  std.debug.print("expect : {s}\n", .{expectedHash});
}
