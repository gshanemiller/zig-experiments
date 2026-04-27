const std = @import("std");

const TransportConfig = struct {
  fn powerOfTwo(value: u32) bool {
    return value>0 and (value&(value-1))==0;
  }

  const HugePageAllocator = struct {
    Name: []const u8,
    HugePageCount: u32,
    SizeKB: u32,

    pub fn verify(self: HugePageAllocator) bool {
      return self.Name.len>0 and self.HugePageCount>0 and self.SizeKB>0;
    } 
  };

  const HeapAllocator = struct {
    Name: []const u8,
    SizeKB: u32,

    pub fn verify(self: HeapAllocator) bool {
      return self.Name.len>0 and self.SizeKB>0;
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

    pub fn verify(self: SRPT) bool {
      var ret =
        self.Name.len>0                     and
        powerOfTwo(self.Capacity)           and 
        self.OverCommitmentCount>0          and
        powerOfTwo(self.ResponseRingCount)  and
        self.ResponseRingCount>4            and
        powerOfTwo(self.RequestRingCount)   and
        self.RequestRingCount>4             and
        self.UnscheduledPriority.len==6     and
        self.ScheduledPriority.len==2;

      // Bail if bad
      if (ret==false) {
        return ret;
      }

      // Make sure non-zero in increasing order
      for (self.UnscheduledPriority, 0..) |value, i| {
        ret = ret and (value>0);
        if (i>0) {
          ret = ret and (value>self.UnscheduledPriority[i-i]);
        }
      }

      ret = ret and (self.ScheduledPriority[0]>0);
      ret = ret and (self.ScheduledPriority[1]>self.ScheduledPriority[0]);
      ret = ret and (self.ScheduledPriority[0]>self.UnscheduledPriority[5]);

      return ret;
    }
  };

  const NIC = struct {
    Manufacture: []const u8,
    Name: []const u8,
    MACAddress: []const u8,
    IPV4Address: []const u8,
    PciDeviceId: []const u8,
    MTUSizeBytes: u32,
    LinkSpeedGbit: u32,
    MaximumTransports: u32,
    SRPTCPUHWcore: u32,
    Allocator: []const u8,

    pub fn verify(self: NIC) bool {
      return
        self.Manufacture.len>0    and
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
    }
  };

  const RXQ = struct {
    Name: []const u8,
    MempoolName: []const u8,
    RingSize: u32,

    pub fn verify(self: RXQ) bool {
      return
        self.Name.len>0           and
        self.MempoolName.len>0    and
        powerOfTwo(self.RingSize) and
        self.RingSize>4;
    }
  };

  const TXQ = struct {
    Name: []const u8,
    MempoolName: []const u8,
    RingSize: u32,

    pub fn verify(self: TXQ) bool {
      return
        self.Name.len>0           and
        self.MempoolName.len>0    and
        powerOfTwo(self.RingSize) and
        self.RingSize>4;
    }
  };

  const QueuePair = struct {
    RXQName: []const u8,
    TXQName: []const u8,
    NICName: []const u8,

    pub fn verify(self: QueuePair) bool {
      return
        self.RXQName.len>0  and
        self.TXQName.len>0  and
        self.NICName.len>0;
    }
  };

  const IPV4Endpoint = struct {
    Port: u32,
    VLANId: u32,

    pub fn verify(self: IPV4Endpoint) bool {
      return
        self.Port>0       and
        self.Port<65536   and
        self.VLANId>=0    and
        self.VLANId<2048;
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

    pub fn verify(self: TransportItem) bool {
      return  
        self.Name.len>0                   and
        self.CPUHWcore>=0                 and
        self.CPUHWcore<256                and
        self.QueuePair.verify()           and
        self.IPV4Endpoint.verify()        and
        self.ErrorIPV4Endpoint.verify()   and
        powerOfTwo(self.CallbackCapacity) and
        powerOfTwo(self.ReadyCapacity)    and
        self.ReadyCapacity>=8             and
        self.ReadyCapacity<=256           and
        powerOfTwo(self.ReserveCapacity)  and
        self.ReserveCapacity>=8           and
        self.ReserveCapacity<=256         and
        self.Allocator.len>0;
    }
  };

  const Primary = struct {
    HugePageAllocator: []HugePageAllocator,
    HeapAllocator: []HeapAllocator,
    SRPT: SRPT,
    NIC: NIC,
    RXQ: []RXQ,
    TXQ: []TXQ,
    Transport: []TransportItem,

    pub fn verify(self: Primary) bool {
      var ret = (self.HugePageAllocator.len>0 or self.HeapAllocator.len>0);
      ret = ret and (self.RXQ.len>0 and self.TXQ.len>0 and self.RXQ.len==self.TXQ.len);
      ret = ret and (self.RXQ.len<=1024);
      for (self.HugePageAllocator) |item| {
        ret = ret and item.verify();
      }
      for (self.HeapAllocator) |item| {
        ret = ret and item.verify();
      }
      ret = ret and self.SRPT.verify();
      ret = ret and self.NIC.verify();
      for (self.Transport) |item| {
        ret = ret and item.verify();
      }

      return ret;
    }
  };

  const TransportRoot = struct {
    Primary: Primary,

    pub fn verify(self: TransportRoot) bool {
      return self.Primary.verify();
    }
  };

  const Root = struct {
    Transport: TransportRoot,

    pub fn verify(self: Root) bool {
      return self.Transport.verify();
    }
  };

  parsed: std.json.Parsed(Root),

  pub fn init(self: *@This(), allocator: std.mem.Allocator, io: std.Io) !void {
    const json = try std.Io.Dir.cwd().readFileAlloc(io, "./transport.json", allocator, .limited(8 * 1024),);
    defer allocator.free(json);
    self.parsed = try std.json.parseFromSlice(Root, allocator, json, .{},);
    defer self.parsed.deinit();
    const root = self.parsed.value;
    // Example usage
    std.debug.print("First HugePageAllocator: {s}\n",
        .{root.Transport.Primary.HugePageAllocator[0].Name});
    std.debug.print("pass basic verify: {}\n", .{root.verify()});
  }
};

pub fn main(init: std.process.Init) !void {
  var jsonConfig: TransportConfig = undefined;
  try jsonConfig.init(init.gpa, init.io);
}
