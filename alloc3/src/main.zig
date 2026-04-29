const std = @import("std");
const config = @import("config");
const c = @import("c");

const AllocatorStats = struct {
  capacityBytes:        u64,
  freeBytes:            u64,
  freeCount:            u64,
  allocCount:           u64,
  totalFreeBytes:       u64,
  totalAllocatedBytes:  u64,
  totalPaddingBytes:    u64,
  name: []const u8,

  fn invariant(self: AllocatorStats) bool {
    return (self.capacityBytes==(self.freeBytes+self.totalPaddingBytes+self.totalAllocatedBytes));
  }

  pub fn init(self: *@This(), capacityBytes: u64, name: []const u8) void {
    self.capacityBytes = capacityBytes;
    self.reset();
    self.name = name;
    std.debug.assert(self.invariant());
  }

  pub fn countAlloc(self: *@This(), bytes: u64, paddingBytes: u64) void {
    std.debug.assert(bytes>0);
    self.freeBytes -= (bytes+paddingBytes);
    self.totalPaddingBytes += paddingBytes;
    self.allocCount += 1;
    self.totalAllocatedBytes += (bytes);
    std.debug.assert(self.invariant());
  }

  pub fn countFree(self: *@This(), bytes: u64) void {
    std.debug.assert(bytes>0);
    self.freeCount += 1;
    self.totalFreeBytes += bytes;
    std.debug.assert(self.invariant());
  }

  pub fn reset(self: *@This()) void {
    std.debug.assert(self.capacityBytes>0);
    std.debug.assert(self.name.len>0);
    self.freeBytes = self.capacityBytes;
    self.freeCount = 0;
    self.allocCount = 0;
    self.totalFreeBytes = 0;
    self.totalAllocatedBytes = 0;
    self.totalPaddingBytes = 0;
    std.debug.assert(self.invariant());
  }

  pub fn print(self: *@This()) void {
    std.log.debug("name (fixed)         : {s}", .{self.name});
    std.log.debug("----------------------------", .{});
    std.log.debug("freeBytes            : {d}", .{self.freeBytes});
    std.log.debug("capacityBytes        : {d}", .{self.capacityBytes});
    std.log.debug("allocatedBytes       : {d}", .{self.capacityBytes-self.freeBytes});
    std.log.debug("freeCount            : {d}", .{self.freeCount});
    std.log.debug("allocCount:          : {d}", .{self.allocCount});
    std.log.debug("totalFreeBytes:      : {d}", .{self.totalFreeBytes});
    std.log.debug("totalAllocatedBytes  : {d}", .{self.totalAllocatedBytes});
    std.log.debug("totalPaddingBytes    : {d}", .{self.totalPaddingBytes});
  }
};

const FixedSizeAllocator = struct {
  memory: []u8,
  offset: u64,
  alignment: u64,
  numa: i32,
  stat: AllocatorStats,

  fn invariant(self: *@This()) bool {
    return (self.offset<=self.memory.len) and self.offset==(self.stat.totalPaddingBytes+self.stat.totalAllocatedBytes);
  }
  
  pub fn init(self: *@This(), capacity: u64, alignment: u64, numa: i32, name: []const u8) !void {
    std.debug.assert(capacity>=1024);
    std.debug.assert(0==(capacity%1024));
    std.debug.assert(alignment>0);
    std.debug.assert(alignment<=64);
    std.debug.assert((alignment&(alignment-1))==0);
    std.debug.assert(numa>=0);
    std.debug.assert(numa<=128);

    // Allocate memory NUMA aligned
    const rawPtr = c.numa_alloc_onnode(capacity, numa);
    const optRawPtr: ?*anyopaque = rawPtr;
    if (optRawPtr) |ptr| {
      var zigPtr: [*]u8 = @ptrCast(ptr);
      self.memory = zigPtr[0..capacity];
      std.debug.assert(self.memory.ptr==zigPtr);
      std.debug.assert(self.memory.len==capacity);
      std.log.debug("allocated {d} bytes on NUMA node {d} as {any}", .{capacity, numa, self.memory.ptr});
    } else {
      std.debug.panic("failed to allocate {d} bytes on NUMA node {d}", .{capacity, numa});
    }

    // Finish init
    self.stat.init(capacity, name);
    self.offset = 0;
    self.alignment = alignment;
    self.numa = numa;
    std.debug.assert(self.invariant());
  }

  pub fn deinit(self: *@This()) void {
    c.numa_free(self.memory.ptr, self.stat.capacityBytes);
    std.log.debug("deallocated {d} bytes at {any} on NUMA node {d}", .{self.stat.capacityBytes, self.memory.ptr, self.numa});
  }

  pub fn print(self: *@This()) void {
    std.log.debug("name (fixed)         : {s}", .{self.stat.name});
    std.log.debug("----------------------------", .{});
    std.log.debug("begin                : {any}", .{self.memory.ptr});
    std.log.debug("end                  : {any}", .{self.memory.ptr+self.memory.len});
    std.log.debug("size                 : {d}", .{self.memory.len});
    std.log.debug("offset               : {d}", .{self.offset});
    std.log.debug("alignment            : {d}", .{self.alignment});
    std.log.debug("numaNode             : {d}", .{self.numa});
  }

  pub fn printStat(self: *@This()) void {
    self.stat.print();
  }

  pub fn alloc(self: *@This(), comptime T: type, count: u64) std.mem.Allocator.Error![]T {
    std.debug.assert(@sizeOf(T)>0);
    std.debug.assert(count>0);
    const bytes = @sizeOf(T)*count;

    // Check if sufficient memory
    if ((self.offset+bytes)>self.memory.len) {
      std.log.debug("cannot allocate {d} bytes ({d} bytes * {d} type {s}) from '{s}' with {d} free bytes",
        .{bytes, @sizeOf(T), count, @typeName(T), self.stat.name, self.stat.freeBytes});
      return std.mem.Allocator.Error.OutOfMemory;
    }

    // Prepare return value
    const ptr = self.memory.ptr+self.offset;
    const ret = ptr[0..bytes];
    std.debug.assert(ret.ptr==(self.memory.ptr+self.offset));
    std.debug.assert(ret.len==bytes);
    std.debug.assert(self.invariant());

    // Do book keeping
    const paddingBytes = self.alignment - ((self.offset+bytes) & (self.alignment-1));
    std.debug.assert(paddingBytes<=self.alignment);
    self.stat.countAlloc(bytes, paddingBytes);
    self.offset += (bytes+paddingBytes);

    std.log.debug("alloc {any} bytes {d} ({d} bytes * {d} type {s}) from '{s}'",
      .{ret.ptr, ret.len,  @sizeOf(T), count, @typeName(T), self.stat.name});

    // Return
    return ret;
  }

  pub fn free(self: *@This(), comptime T: type, slice: []T) void {
    std.log.debug("free  {any} bytes {d} type {s} to '{s}'",
      .{slice.ptr, slice.len,  @typeName(T), self.stat.name});
    self.stat.countFree(slice.len);
    std.debug.assert(self.invariant());
  }

  pub fn reset(self: *@This(), alignment: u64) void {
    std.debug.assert(alignment>0);
    std.debug.assert(alignment<=64);
    std.debug.assert((alignment&(alignment-1))==0);
    self.offset = 0;
    self.stat.reset();
    self.alignment = alignment;
    std.debug.assert(self.invariant());
  }
};

fn work(mem: *FixedSizeAllocator, n: u64) void {
  if (mem.alloc(u8, n)) |slice| {
    mem.free(u8, slice);
  } else |err| {
    std.log.debug("error: {any}", .{err});
  }
}

pub fn main() !void {
  var mem: FixedSizeAllocator = undefined;
  try mem.init(16*1024, 8, 0, "bubba");

  work(&mem, 1);
  work(&mem, 1);
  work(&mem, 4);
  work(&mem, 3);
  work(&mem, 8);
  work(&mem, 10);
  work(&mem, 17);
  work(&mem, 32);

  mem.printStat();
  mem.deinit();
}
