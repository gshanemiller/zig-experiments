const std = @import("std");

fn addExecutable(b: *std.Build, disableAssert: bool, optimize: std.builtin.OptimizeMode, 
  target: std.Build.ResolvedTarget, binding_c: *std.Build.Step.TranslateC,
  libName: []const u8, exeName: []const u8) !void {

    const libsimdjson = b.addLibrary(.{
        .name = libName,
        .linkage = .static,
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/simdjson.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    libsimdjson.root_module.addCSourceFile(.{
        .file = b.path("./ext/json/json.cpp"),
        .flags = &.{""},
        .language = std.Build.Module.CSourceLanguage.cpp,
    });
    libsimdjson.root_module.addCSourceFile(.{
        .file = b.path("./ext/json/simdjson/simdjson.cpp"),
        .flags = &.{""},
        .language = std.Build.Module.CSourceLanguage.cpp,
    });

    libsimdjson.root_module.addIncludePath(b.path("ext/json"));
    libsimdjson.root_module.addIncludePath(b.path("ext/json/simdjson"));
    libsimdjson.root_module.addIncludePath(b.path("ext/json/stringzilla"));

    if (disableAssert) {
      libsimdjson.root_module.addCMacro("NDEBUG", "1");
    }
    libsimdjson.root_module.addCMacro("SIMDJSON_AVX512_ALLOWED", "0");
    libsimdjson.root_module.addCMacro("SIMDJSON_IMPLEMENTATION_HASWELL", "1");
    libsimdjson.root_module.addCMacro("SIMDJSON_EXCEPTIONS", "0");
    libsimdjson.root_module.addCMacro("SIMDJSON_THREADS_ENABLED", "0");
    libsimdjson.root_module.addCMacro("SZ_USE_HASWELL", "1");
    libsimdjson.root_module.addCMacro("SZ_AVOID_LIBC", "0");
    libsimdjson.root_module.link_libcpp = true;

    const exe = b.addExecutable(.{                                                                                      
        .name = exeName,
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
   b.installArtifact(exe);
}

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const binding_c = b.addTranslateC(.{
      .root_source_file = b.path("ext/json/json_binding.h"),
      .target = target,
      .optimize = optimize,
    });
    binding_c.addIncludePath(b.path("ext/json"));

    try addExecutable(b, false, std.builtin.OptimizeMode.Debug, target, binding_c,
      "libsimdjson.debug", "main.debug");
    try addExecutable(b, false, std.builtin.OptimizeMode.ReleaseSafe, target, binding_c,
      "libsimdjson.release_safe", "main.release_safe");
    try addExecutable(b, true, std.builtin.OptimizeMode.ReleaseFast, target, binding_c,
      "libsimdjson.release_fast", "main.release_fast");
    try addExecutable(b, true, std.builtin.OptimizeMode.ReleaseSmall, target, binding_c,
      "libsimdjson.release_small", "main.release_small");
}
