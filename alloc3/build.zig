const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const buildOptions = .{                                                                                               
      .debugAllocator = b.option(                                                                                              
        bool,                                                                                                       
        "debugAlloc",                                                                                                      
        "stuff"
      ),
    };

    const numa_c = b.addTranslateC(.{
      .root_source_file = b.path("numa.h"),
      .target = target,
      .optimize = optimize,
    });
    numa_c.linkSystemLibrary("numa", .{});

    const mod = b.addModule("alloc", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
    });

    const exe = b.addExecutable(.{
        .name = "alloc",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "bs", .module = mod },
                .{ .name = "config", .module = mod},
                .{ .name = "c", .module = numa_c.createModule()},
            },
        }),
    });

    const exeOptions = b.addOptions();                                                                                    
    exeOptions.addOption(bool, "debugAlloc", buildOptions.debugAllocator orelse false);                                        
    exe.root_module.addOptions("config", exeOptions);                                                               

    b.installArtifact(exe);

}
