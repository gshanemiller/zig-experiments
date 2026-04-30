const std = @import("std");

pub fn build(b: *std.Build) void {
  const target = b.standardTargetOptions(.{});
  const optimize = b.standardOptimizeOption(.{});
  const includeDir = std.Build.LazyPath{.cwd_relative = "/usr/include"};
  const libDir = std.Build.LazyPath{.cwd_relative = "/usr/lib/x86_64-linux-gnu"};

  const numa_c = b.addTranslateC(.{
    .root_source_file = b.path("numa.h"),
    .target = target,
    .optimize = optimize,
  });

  numa_c.addIncludePath(includeDir);
  numa_c.addFrameworkPath(libDir);
  numa_c.addSystemFrameworkPath(libDir);
  numa_c.linkSystemLibrary("numa", .{});                                

  const mod = b.addModule("ccode", .{
    .root_source_file = b.path("src/root.zig"),
    .target = target,
  });

  const exe = b.addExecutable(.{
    .name = "ccode",
    .root_module = b.createModule(.{
      .root_source_file = b.path("src/main.zig"),
      .target = target,
      .optimize = optimize,
      .imports = &.{
        .{ .name = "ccode", .module = mod },
        .{ .name = "c", .module = numa_c.createModule()},
      },
    }),
  });

  b.installArtifact(exe);
}
