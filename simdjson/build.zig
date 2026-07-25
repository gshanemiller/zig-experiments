const std = @import("std");

// Although this function looks imperative, it does not perform the build
// directly and instead it mutates the build graph (`b`) that will be then
// executed by an external runner. The functions in `std.Build` implement a DSL
// for defining build steps and express dependencies between them, allowing the
// build runner to parallelize the build automatically (and the cache system to
// know when a step doesn't need to be re-run).
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const binding_c = b.addTranslateC(.{
      .root_source_file = b.path("ext/json/json_binding.h"),
      .target = target,
      .optimize = optimize,
    });
    binding_c.addIncludePath(b.path("ext/json"));

    const libstringzilla = b.addLibrary(.{
        .name = "simdjson",
        .linkage = .static,
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/stringzilla.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    libstringzilla.root_module.addCSourceFile(.{
        .file = b.path("ext/json/json.c"),
        .flags = &.{ "-O2", "-march=native", "-mtune=native", "-Wall", "-DSZ_USE_HASWELL=1", "-DSZ_AVOID_LIBC=0" },
    });
    libstringzilla.root_module.addIncludePath(b.path("ext/json"));
    libstringzilla.root_module.addIncludePath(b.path("ext/json/stringzilla"));
    libstringzilla.root_module.addSystemIncludePath(.{.cwd_relative = "/usr/include/x86_64-linux-gnu"});
    libstringzilla.root_module.addSystemIncludePath(.{.cwd_relative = "/usr/include"});
    libstringzilla.root_module.addCMacro("SZ_USE_HASWELL", "1");
    libstringzilla.root_module.addCMacro("SZ_AVOID_LIBC", "0");

    const libsimdjson = b.addLibrary(.{
        .name = "simdjson",
        .linkage = .static,
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/simdjson.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    libsimdjson.root_module.addCSourceFile(.{
        .file = b.path("./ext/json/json.cpp"),
        .flags = &.{ "-O2", "-std=c++23", "-march=native", "-mtune=native", "-Wall", "-DSIMDJSON_AVX512_ALLOWED=0", "-DSIMDJSON_IMPLEMENTATION_HASWELL=1", "-DSIMDJSON_EXCEPTIONS=0", "-DSIMDJSON_THREADS_ENABLED=0" },
    });
    libsimdjson.root_module.addCSourceFile(.{
        .file = b.path("./ext/json/simdjson/simdjson.cpp"),
        .flags = &.{ "-O2", "-std=c++23", "-march=native", "-mtune=native", "-Wall", "-DSIMDJSON_IMPLEMENTATION_HASWELL=1", "-DSIMDJSON_EXCEPTIONS=0" },
    });
    libsimdjson.root_module.addIncludePath(b.path("ext/json"));
    libsimdjson.root_module.addIncludePath(b.path("ext/json/simdjson"));
    libsimdjson.root_module.addSystemIncludePath(.{.cwd_relative = "/usr/include/x86_64-linux-gnu"});
    libsimdjson.root_module.addSystemIncludePath(.{.cwd_relative = "/usr/include/x86_64-linux-gnu/c++/13"});
    libsimdjson.root_module.addSystemIncludePath(.{.cwd_relative = "/usr/include/c++/13"});
    libsimdjson.root_module.addSystemIncludePath(.{.cwd_relative = "/usr/include"});
    libsimdjson.root_module.addCMacro("SIMDJSON_AVX512_ALLOWED", "0");
    libsimdjson.root_module.addCMacro("SIMDJSON_IMPLEMENTATION_HASWELL", "1");
    libsimdjson.root_module.addCMacro("SIMDJSON_EXCEPTIONS", "0");
    libsimdjson.root_module.addCMacro("SIMDJSON_THREADS_ENABLED", "0");
    libsimdjson.root_module.addCMacro("SIMDJSON_THREADS_ENABLED", "0");

    const exe = b.addExecutable(.{                                                                                      
        .name = "main",                                                                                                  
        .root_module = b.createModule(.{                                                                                
            .root_source_file = b.path("src/main.zig"),
            .target = target,                                                                                           
            .optimize = optimize,                                                                                       
            .imports = &.{                                                                                              
                .{ .name = "binding_c", .module = binding_c.createModule()},
            },                                                                                                          
        }),                                                                                                             
    }); 
   exe.root_module.linkLibrary(libsimdjson);
   exe.root_module.linkLibrary(libstringzilla);
   exe.root_module.linkSystemLibrary("stdc++", .{}); 
   b.installArtifact(exe);
}
