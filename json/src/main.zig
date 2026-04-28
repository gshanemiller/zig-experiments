const std = @import("std");

const TransportConfig = struct {
  fn powerOfTwo(value: u32) bool {
    return value>0 and (value&(value-1))==0;
  }

  fn addName(name: []const u8, map: *std.hash_map.StringHashMap(bool)) bool {
    std.debug.assert(name.len>0);
    var ret = false;
    if (!map.contains(name)) {
      if (map.put(name, true)) |result| {
        _ = result;
        ret = true;
      } else |err| {
        std.log.err("transportConfig map error: {any} on {s}\n", .{err, name});
      }
    } else {
      std.log.err("transportConfig name '{s}' duplicated\n", .{name});
    }
    return ret;
  }

  const HugePageAllocator = struct {
    Name: []const u8,
    HugePageCount: u32,
    SizeKB: u32,

    pub fn verify(self: HugePageAllocator, allocator: std.mem.Allocator, map: *std.hash_map.StringHashMap(bool)) bool {
      std.log.debug("verifying hugePageAllocator name '{s}'", .{self.Name});

      // Not used
      _ = allocator;

      var ret = 
        self.Name.len>0       and
        self.HugePageCount>0  and
        self.SizeKB>0;

      // Add name
      if (ret) {
        // Protect against zero length names
        ret = ret and addName(self.Name, map);
      }

      // Return result
      return ret;
    } 
  };

  const HeapAllocator = struct {
    Name: []const u8,
    SizeKB: u32,

    pub fn verify(self: HeapAllocator, allocator: std.mem.Allocator, map: *std.hash_map.StringHashMap(bool)) bool {
      std.log.debug("verifying heapAllocator name '{s}'", .{self.Name});

      // Not used
      _ = allocator;

      var ret =
        self.Name.len>0 and
        self.SizeKB>0;

      // Add name
      if (ret) {
        // Protect against zero length names
        ret = ret and addName(self.Name, map);
      }

      // Return result
      return ret;
    } 
  };

  const SRPT = struct {
    Name: []const u8,
    Capacity: u32,
    OverCommitmentCount: u32,
    ResponseRingCount: u32,
    RequestRingCount: u32,
    UnscheduledPriority: []u32,
    ScheduledPriority: []u32,
    Allocator: []const u8,

    pub fn verify(self: SRPT, allocator: std.mem.Allocator, map: *std.hash_map.StringHashMap(bool)) bool {
      std.log.debug("verifying SRPT name '{s}'", .{self.Name});

      // Not used
      _ = allocator;

      var ret =
        self.Name.len>0                     and
        powerOfTwo(self.Capacity)           and 
        self.OverCommitmentCount>0          and
        powerOfTwo(self.ResponseRingCount)  and
        self.ResponseRingCount>4            and
        powerOfTwo(self.RequestRingCount)   and
        self.RequestRingCount>4             and
        self.UnscheduledPriority.len==6     and
        self.ScheduledPriority.len==2       and
        self.Allocator.len>0;

      // Bail if bad
      if (!ret) {
        return ret;
      }

      // Make sure priorities in strict increasing order non-zero
      for (self.UnscheduledPriority, 0..) |value, i| {
        ret = ret and (value>0);
        if (i>0) {
          ret = ret and (value>self.UnscheduledPriority[i-i]);
        }
      }
      // Scheduled priorities must exceed unscheduled priorities
      ret = ret and (self.ScheduledPriority[0]>0);
      ret = ret and (self.ScheduledPriority[1]>self.ScheduledPriority[0]);
      ret = ret and (self.ScheduledPriority[0]>self.UnscheduledPriority[5]);

      // Add name to map
      ret = ret and addName(self.Name, map);

      // Cross reference names
      ret = ret and map.contains(self.Allocator);

      // Return result
      return ret;
    }
  };

  const NIC = struct {
    Model: []const u8,
    Name: []const u8,
    MACAddress: []const u8,
    IPV4Address: []const u8,
    PciDeviceId: []const u8,
    MTUSizeBytes: u32,
    LinkSpeedGbit: u32,
    MaximumTransports: u32,
    SRPTCPUHWcore: u32,
    Allocator: []const u8,

    pub fn verify(self: NIC, allocator: std.mem.Allocator, map: *std.hash_map.StringHashMap(bool)) bool {
      std.log.debug("verifying NIC name '{s}' model '{s}'", .{self.Name, self.Model});

      // Not used
      _ = allocator;

      var ret = 
        self.Model.len>0          and
        self.Name.len>0           and
        self.MACAddress.len==17   and
        self.IPV4Address.len>0    and
        self.PciDeviceId.len==12  and
        self.MTUSizeBytes>0       and
        self.MTUSizeBytes<65536   and
        self.LinkSpeedGbit>0      and
        self.MaximumTransports>0  and
        self.MaximumTransports<9  and
        self.SRPTCPUHWcore>=0     and
        self.SRPTCPUHWcore<256    and
        self.Allocator.len>0;

      // Bail if bad
      if (!ret) {
        return ret;
      }

      // Add names
      ret = ret and addName(self.Name, map);
      ret = ret and addName(self.MACAddress, map);
      ret = ret and addName(self.IPV4Address, map);
      ret = ret and addName(self.PciDeviceId, map);

      // Cross-reference names
      ret = ret and map.contains(self.Allocator);

      // Return result
      return ret;
    }
  };

  const RXQ = struct {
    Name: []const u8,
    MempoolName: []const u8,
    RingSize: u32,

    pub fn verify(self: RXQ, allocator: std.mem.Allocator, map: *std.hash_map.StringHashMap(bool)) bool {
      std.log.debug("verifying RXQ name '{s}'", .{self.Name});

      // Not used
      _ = allocator;

      var ret =
        self.Name.len>0           and
        self.MempoolName.len>0    and
        powerOfTwo(self.RingSize) and
        self.RingSize>4;

      // Add names
      if (ret) {
        // Protect against zero length names
        ret = ret and addName(self.Name, map);
      }

      // Return result
      return ret;
    }
  };

  const TXQ = struct {
    Name: []const u8,
    MempoolName: []const u8,
    RingSize: u32,

    pub fn verify(self: TXQ, allocator: std.mem.Allocator, map: *std.hash_map.StringHashMap(bool)) bool {
      std.log.debug("verifying TXQ name '{s}'", .{self.Name});

      // Not used
      _ = allocator;

      var ret =
        self.Name.len>0           and
        self.MempoolName.len>0    and
        powerOfTwo(self.RingSize) and
        self.RingSize>4;

      // Add names
      if (ret) {
        // Protect against zero length names
        ret = ret and addName(self.Name, map);
      }

      // Return result
      return ret;
    }
  };

  const QueuePair = struct {
    RXQName: []const u8,
    TXQName: []const u8,
    NICName: []const u8,

    pub fn verify(self: QueuePair, allocator: std.mem.Allocator, map: *std.hash_map.StringHashMap(bool)) bool {
      std.log.debug("verifying queuePair rxqName '{s}' txQName '{s}' nicName '{s}'", .{self.RXQName, self.TXQName, self.NICName});

      // Not used
      _ = allocator;

      var ret =
        self.RXQName.len>0  and
        self.TXQName.len>0  and
        self.NICName.len>0;

      // Cross reference names
      ret = ret and map.contains(self.RXQName);
      ret = ret and map.contains(self.TXQName);
      ret = ret and map.contains(self.NICName);

      // Return result
      return ret;
    }
  };

  const IPV4Endpoint = struct {
    Port: u32,
    VLANId: u32,

    pub fn verify(self: IPV4Endpoint, allocator: std.mem.Allocator, map: *std.hash_map.StringHashMap(bool)) bool {
      std.log.debug("verifying endpoint vlanId '{d}' port '{d}'", .{self.VLANId, self.Port});

      var ret =
        self.Port>0       and
        self.Port<65536   and
        self.VLANId>=0    and
        self.VLANId<4096;

      // Bail of error
      if (!ret) {
        return ret;
      }

      // Make string for vlan/port pair
      if (std.fmt.allocPrint(allocator, "IPV4Endpoint:{d}:{d}", .{self.Port, self.VLANId})) |value| {
        ret = ret and addName(value, map);
      } else |err| {
        std.log.err("transportConfig allocation error: {any}\n", .{err});
        ret = false;
      }

      // Return result
      return ret;
    }
  };

  const TransportItem = struct {
    Name: []const u8,
    CPUHWcore: u32,
    QueuePair: QueuePair,
    IPV4Endpoint: IPV4Endpoint,
    ErrorIPV4Endpoint: IPV4Endpoint,
    CallbackCapacity: u32,
    ReadyCapacity: u32,
    ReserveCapacity: u32,
    Allocator: []const u8,

    pub fn verify(self: TransportItem, allocator: std.mem.Allocator, map: *std.hash_map.StringHashMap(bool)) bool {
      std.log.debug("verifying transport item '{s}'", .{self.Name});

      var ret =
        self.Name.len>0                   and
        self.CPUHWcore>=0                 and
        self.CPUHWcore<256                and
        powerOfTwo(self.CallbackCapacity) and
        powerOfTwo(self.ReadyCapacity)    and
        self.ReadyCapacity>=8             and
        self.ReadyCapacity<=256           and
        powerOfTwo(self.ReserveCapacity)  and
        self.ReserveCapacity>=8           and
        self.ReserveCapacity<=256         and
        self.Allocator.len>0;

        // Bail if error
        if (!ret) {
          return ret;
        }

        // Verify fields
        ret = ret and self.QueuePair.verify(allocator, map);
        ret = ret and self.IPV4Endpoint.verify(allocator, map);
        ret = ret and self.ErrorIPV4Endpoint.verify(allocator, map);
        ret = ret and map.contains(self.Allocator); 

        // Add name
        ret = ret and addName(self.Name, map);

        // Return result
        return ret;
    }
  };

  const TransportSetItem = struct {
    HugePageAllocator: []HugePageAllocator,
    HeapAllocator: []HeapAllocator,
    SRPT: SRPT,
    NIC: NIC,
    RXQ: []RXQ,
    TXQ: []TXQ,
    Transport: []TransportItem,

    pub fn verify(self: TransportSetItem, allocator: std.mem.Allocator, map: *std.hash_map.StringHashMap(bool)) bool {
      std.log.debug("verifying transport item set", .{});

      var ret = (self.HugePageAllocator.len>0 or self.HeapAllocator.len>0);
      ret = ret and (self.RXQ.len>0 and self.TXQ.len>0 and self.RXQ.len==self.TXQ.len);
      ret = ret and (self.RXQ.len<=1024);

      // Verify fields
      for (self.HugePageAllocator) |item| {
        ret = ret and item.verify(allocator, map);
      }
      for (self.HeapAllocator) |item| {
        ret = ret and item.verify(allocator, map);
      }
      for (self.RXQ) |item| {
        ret = ret and item.verify(allocator, map);
      }
      for (self.TXQ) |item| {
        ret = ret and item.verify(allocator, map);
      }
      ret = ret and self.SRPT.verify(allocator, map);
      ret = ret and self.NIC.verify(allocator, map);
      for (self.Transport) |item| {
        ret = ret and item.verify(allocator, map);
      }

      // Return result
      return ret;
    }
  };

  const Root = struct {
    TransportSet: []TransportSetItem,

    pub fn verify(self: Root, allocator: std.mem.Allocator, map: *std.hash_map.StringHashMap(bool)) bool {
      var ret = self.TransportSet.len==1;
      for (self.TransportSet) |item| {
        ret = ret and item.verify(allocator, map);
        if (!ret) {
          break;
        }
      }
      return ret;
    }
  };

  root: Root,

  pub fn init(self: *@This(), fileName: []const u8, allocator: std.mem.Allocator, io: std.Io) !void {
    std.log.debug("processing transport configuration '{s}'", .{fileName});
    const json = try std.Io.Dir.cwd().readFileAlloc(io, fileName, allocator, .limited(8 * 1024),);
    defer allocator.free(json);
    const parsed = try std.json.parseFromSlice(Root, allocator, json, .{},);
    defer parsed.deinit();
    self.root = parsed.value;
    std.log.debug("verifying transport configuration '{s}'", .{fileName});
    var nameMap: std.hash_map.StringHashMap(bool) = .init(allocator);
    std.debug.print("verify: {}\n", .{self.root.verify(allocator, &nameMap)});
    // free keys allocated in IPV4Endpoint
    var moreWork = true;
    while (moreWork) {
      moreWork = false;
      var iter = nameMap.keyIterator();
      while (iter.next()) |key| {
        std.log.info("outer: key: {s}", .{key.*});
        if (std.mem.startsWith(u8, key.*, "IPV4Endpoint:")) {
          const ptr = key.*;
          if (nameMap.remove(key.*)) {
            allocator.free(ptr);
          }
          moreWork = true;
          break;
        }
      }
    }
    nameMap.clearAndFree();
  }
};

pub fn main(init: std.process.Init) !void {
  var jsonConfig: TransportConfig = undefined;
  try jsonConfig.init("transport.json", init.gpa, init.io);
}
