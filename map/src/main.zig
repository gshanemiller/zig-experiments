const std = @import("std");

pub const DefaultAllocator = struct {
  pub fn createType(debug: bool, limitKb: usize) type {
    return struct {
      const DebugAllocatorType = std.heap.DebugAllocator(.{
        .stack_trace_frames = 10,
        .enable_memory_limit = true,
        .safety = true,
        .thread_safe = true,
        .verbose_log = debug,
        .backing_allocator_zeroes = false,
        .page_size = 4096,
      });

      heapDebugAllocator: DebugAllocatorType,

      pub fn init(self: *@This()) void {
        self.heapDebugAllocator = DebugAllocatorType{.backing_allocator = std.heap.page_allocator,};
        self.heapDebugAllocator.requested_memory_limit = limitKb*1024;
        std.debug.assert(self.heapDebugAllocator.requested_memory_limit>=1024);
      }

      pub fn deinit(self: *@This()) void {
        const leakStatus = self.heapDebugAllocator.deinit();
        if (leakStatus == .leak) {
          std.debug.panic("{s}\n", .{"memory leaked"});
        }
      }

      pub fn allocator(self: *@This()) std.mem.Allocator {
        return self.heapDebugAllocator.allocator();
      }
    };
  }
};

const Test = struct {
  f1: u32,
  f2: []const u8,
};

pub fn main() !void {
  const MyAllocType = DefaultAllocator.createType(true, 5);
  var myAlloc: MyAllocType = undefined;
  myAlloc.init();
  const allocator = myAlloc.allocator();

  var map: std.hash_map.StringHashMap(*Test) = .init(allocator);

  var t1 = try allocator.create(Test);
  t1.f1 = 333;
  t1.f2 = "shane";
  std.debug.print("made {any}\n", .{t1});
  try map.put("t1", t1);

  var iter = map.iterator();
  while (iter.next()) |obj| {
    std.debug.print("iter key='{}' value='{any}' value='{any}'\n", .{obj.key_ptr, obj.value_ptr, obj.value_ptr.*});
  }

  var moreWork = true;
  while (moreWork) {
    moreWork = false;
    var diter = map.iterator();
    while (diter.next()) |obj| {
      std.debug.print("iter key='{}' value='{any}' value='{any}'\n", .{obj.key_ptr, obj.value_ptr, obj.value_ptr.*});
      allocator.destroy(obj.value_ptr.*);
      if (map.remove(obj.key_ptr.*)) {
        moreWork = true;
        break;
      }
    }
  }
  map.clearAndFree();

  myAlloc.deinit();
}
