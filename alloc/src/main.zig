const std = @import("std");

fn work1() !void {
  const buffer = try std.heap.page_allocator.alloc(u8, 1024);
  defer std.heap.page_allocator.free(buffer);
  var fixedMemAllocator: std.heap.FixedBufferAllocator = .init(buffer);
  const memAlloc = fixedMemAllocator.allocator();

  for (0..10) |i| {
    _ = i;
    _ = try memAlloc.alloc(u8, 10);
  }
}

fn work2() !void {
  const config: std.heap.DebugAllocatorConfig = .{
    .stack_trace_frames = 10,
    .enable_memory_limit = true,
    .safety = true,
    .thread_safe = false,
    .verbose_log = true,
    .backing_allocator_zeroes = false,
    .page_size = 1024,
  };

  var gpa: std.heap.DebugAllocator(config) = .init;
  gpa.requested_memory_limit = 100;
  const memAlloc = gpa.allocator();
  defer {
    const deinit_status = gpa.deinit();
    // fail test; can't try in defer as defer is executed after we return
    if (deinit_status == .leak) {
      @panic("TEST FAIL");
    }
  }

  for (0..10) |i| {
    _ = i;
    // const ptr = try memAlloc.alloc(u8, 10);
    // memAlloc.free(ptr);
    _ = try memAlloc.alloc(u8, 10);
  }
}


pub fn main() !void {
  try work1();
  try work2();
}
