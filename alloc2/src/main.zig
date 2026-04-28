const std = @import("std");
const config = @import("config");

const AllocatorStats = struct {
  freeBytes:            u64,
  capacityBytes:        u64,
  allocatedBytes:       u64,
  maxNetAllocatedBytes: u64,
  freeCount:            u64,
  allocCount:           u64,
  totalFreeBytes:       u64,
  totalAllocatedBytes:  u64,
  totalPaddingBytes:    u64,
  name: []const u8,

  fn invariant(self: AllocatorStats) bool {
    return (self.freeBytes+self.allocatedBytes)==self.capacityBytes;
  }

  pub fn init(self: *@This(), capacityBytes: u64, name: []const u8) void {
    std.debug.assert(capacityBytes>0);
    std.debug.assert((capacityBytes%1024)==0);
    std.debug.assert(name.len>0);
    self.freeBytes = capacityBytes;
    self.capacityBytes = capacityBytes;
    self.allocatedBytes = 0;
    self.maxNetAllocatedBytes = 0;
    self.freeCount = 0;
    self.allocCount = 0;
    self.totalFreeBytes = 0;
    self.totalAllocatedBytes = 0;
    self.totalPaddingBytes = 0;
    self.name = name;
    std.debug.assert(self.invariant());
  }

  pub fn countAlloc(self: *@This(), bytes: u64, paddingBytes: u64) void {
    std.debug.assert(bytes>0);
    self.freeBytes -= (bytes+paddingBytes);
    self.allocatedBytes += (bytes+paddingBytes);
    std.debug.assert(self.invariant());
    self.totalPaddingBytes += paddingBytes;
    if (self.allocatedBytes>self.maxNetAllocatedBytes) {
      self.maxNetAllocatedBytes = self.allocatedBytes;
    }
    self.allocCount += 1;
    self.totalAllocatedBytes += (bytes+paddingBytes);
  }

  pub fn countFree(self: *@This(), bytes: u64) void {
    std.debug.assert(bytes>0);
    self.freeBytes += bytes;
    self.allocatedBytes -= bytes;
    std.debug.assert(self.invariant());
    self.freeCount += 1;
    self.totalFreeBytes += bytes;
  }

  pub fn print(self: *@This()) void {
    std.log.debug("name                 : {s}", .{self.name});
    std.log.debug("----------------------------", .{});
    std.log.debug("freeBytes            : {d}", .{self.freeBytes});
    std.log.debug("capacityBytes        : {d}", .{self.capacityBytes});
    std.log.debug("allocatedBytes:      : {d}", .{self.allocatedBytes});
    std.log.debug("maxNetAllocatedBytes : {d}", .{self.maxNetAllocatedBytes});
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
  numa: u8,
  stat: AllocatorStats,
  backingAllocator: std.mem.Allocator,
  
  pub fn init(self: *@This(), backingAllocator: std.mem.Allocator, capacityBytes: u64,
    alignment: u64, numa: u8, name: []const u8) !void {
    std.debug.assert(alignment>0);
    std.debug.assert(alignment<=64);
    std.debug.assert((alignment&(alignment-1))==0);
    std.debug.assert(numa>=0);
    std.debug.assert(numa<=128);
    self.stat.init(capacityBytes, name);
    self.backingAllocator = backingAllocator;
    self.memory = try backingAllocator.alloc(u8, capacityBytes);
    self.offset = 0;
    self.alignment = alignment;
    self.numa = numa;
  }

  pub fn deinit(self: *@This()) void {
    self.backingAllocator.free(self.memory);
  }

  pub fn print(self: *@This()) void {
    std.log.debug("name  (fixed)        : {s}", .{self.stat.name});
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

    // Do book keeping
    const paddingBytes = self.alignment - ((self.offset+bytes) & (self.alignment-1));
    std.debug.assert(paddingBytes<self.alignment);
    self.stat.countAlloc(bytes, paddingBytes);
    self.offset += (bytes+paddingBytes);

    std.log.debug("allocated {d} bytes ({d} bytes * {d} type {s}) from '{s}'",
      .{bytes, @sizeOf(T), count, @typeName(T), self.stat.name});

    // Return
    return ret;
  }
};

fn work(mem: *FixedSizeAllocator, n: u64) void {
  if (mem.alloc(u8, n)) |slice| {
    std.log.debug("got {any} {any}", .{slice.ptr, slice.len});
  } else |err| {
    std.log.debug("got {any}", .{err});
  }
}

pub fn main(init: std.process.Init) !void {
  var mem: FixedSizeAllocator = undefined;
  try mem.init(init.gpa, 1024*16, 8, 0, "bubba");
  mem.print();

  work(&mem, 1);
  work(&mem, 1);
  work(&mem, 4);
  work(&mem, 3);

  mem.printStat();
  mem.deinit();
}
