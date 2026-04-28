const std = @import("std");
const config = @import("config");

fn createAllocatorType(comptime isDebug: bool) type {
  if (isDebug) {
    return struct {
      const DebugAllocatorType = std.heap.DebugAllocator(.{
        .stack_trace_frames = 10,
        .enable_memory_limit = true,
        .safety = true,
        .thread_safe = false,
        .verbose_log = true,
        .backing_allocator_zeroes = false,
        .page_size = 1024
        });

      allocator: std.mem.Allocator,
      heapDebugAllocator: ?DebugAllocatorType = null,

      pub fn init(self: *@This()) void {
        self.heapDebugAllocator = DebugAllocatorType{.backing_allocator = std.heap.page_allocator,};
        self.heapDebugAllocator.?.requested_memory_limit = 1024;
        self.allocator = self.heapDebugAllocator.?.allocator();
      }

      pub fn deinit(self: *@This()) void {
        const leakStatus = self.heapDebugAllocator.?.deinit();
        if (leakStatus == .leak) {
          std.debug.panic("{s}\n", .{"memory leaked"});
        }
      }
    };
  } else {
    return struct {
      buffer: ?[]u8,
      allocator: std.mem.Allocator = std.heap.page_allocator,
      fixedHeapAllocator: ?std.heap.FixedBufferAllocator = null,

      pub fn init(self: *@This()) void {
        const tmp = std.heap.page_allocator.alloc(u8, 1024);
        if (tmp) |ptr| {
          self.buffer = ptr;
          self.fixedHeapAllocator = std.heap.FixedBufferAllocator.init(ptr);
          self.allocator = self.fixedHeapAllocator.?.allocator();
        } else |err| {
          std.debug.panic("{any}\n", .{err});
        }
      }

      pub fn deinit(self: *@This()) void {
        std.heap.page_allocator.free(self.buffer.?);
      }
    };
  }
}

fn work0(memAlloc: std.mem.Allocator) !void {
  std.log.info("alloc-dealloc under limit\n", .{});
  for (0..10) |i| {
    _ = i;
    const ptr = try memAlloc.alloc(u8, 10);
    memAlloc.free(ptr);
  }
}

fn work1(memAlloc: std.mem.Allocator) !void {
  std.log.info("alloc without free under limit\n", .{});
  for (0..10) |i| {
    _ = i;
    _ = try memAlloc.alloc(u8, 10);
  }
}

fn work2(memAlloc: std.mem.Allocator) !void {
  std.log.info("alloc over limit\n", .{});
  _ = try memAlloc.alloc(u8, 100000);
}

pub fn main(init: std.process.Init) !void {
  const AllocatorType = createAllocatorType(config.debugAlloc);
  var alloc: AllocatorType = undefined;
  alloc.init();

  const args = try init.minimal.args.toSlice(init.arena.allocator());
  for (args) |arg| {
    if (std.mem.eql(u8, "-work0", arg)) {
      try work0(alloc.allocator);
    } else if (std.mem.eql(u8, "-work1", arg)) {
      try work1(alloc.allocator);
    } else if (std.mem.eql(u8, "-work2", arg)) {
      try work2(alloc.allocator);
    } else {
      std.log.warn("no match\n", .{});
    }
  }

  alloc.deinit();
}
