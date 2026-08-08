const std = @import("std");
const builtin = @import("builtin");
const zon = @import("build.zig.zon");

const LogLevelMax = @as(usize, @intFromEnum(std.log.Level.debug))+1;
const OptimizeModeMax = @as(usize, @intFromEnum(std.builtin.OptimizeMode.Debug))+1;

var buildTargetString: []u8 = "";

const optSuffix = [OptimizeModeMax][]const u8 {
  ".debug",
//".release_safe",
//".release_fast",
//".release_small",
};

const defaultLogLevel = [OptimizeModeMax]std.log.Level {
  std.log.Level.debug,
//std.log.Level.info,
//std.log.Level.info,
//std.log.Level.info,
};

// Maps 1:1 with std.log.Level e.g. 0=error
const externLibLogLevel = [LogLevelMax][]const u8 {
  "0",
  "1",
  "2",
  "3",
};

var externLib: [OptimizeModeMax]*std.Build.Step.Compile = undefined;
var bindingc: [OptimizeModeMax]*std.Build.Step.TranslateC = undefined;

// Compiler must be >= to this verion
const ZigVersion = std.SemanticVersion{
  .major = 0,
  .minor = 16,
  .patch = 0,
};

// Ensure compiler meets or exeeds build requirement
fn isCompilerValid() void {
  const zigVersionEq =
    builtin.zig_version.major == ZigVersion.major and
    builtin.zig_version.minor == ZigVersion.minor and
    builtin.zig_version.patch >= ZigVersion.patch;
  if (!zigVersionEq) {
    @compileError(std.fmt.comptimePrint("unsupported zig version: expected >= {}, found {}",
      .{ZigVersion, builtin.zig_version},));
  }
}

fn concat(b: *std.Build, lhs: []const u8, rhs: []const u8, delimiter: []const u8) ![]u8 {
  return std.fmt.allocPrint(b.allocator, "{s}{s}{s}", .{lhs, delimiter, rhs});
}

fn makePath(b: *std.Build, lhs: []const u8, rhs: []const u8, extension: []const u8) ![]u8 {
  return std.fmt.allocPrint(b.allocator, "{s}{s}{s}", .{lhs, rhs, extension});
}

// Make pretty printed build target description
fn makeBuildTargetString(b: *std.Build, target: std.Target) !void {
  const arch = @tagName(target.cpu.arch);
  const os = @tagName(target.os.tag);
  const abi = @tagName(target.abi);
  buildTargetString = try std.fmt.allocPrint(b.allocator, "{s}-{s}-{s}-{s}",
    .{arch, target.cpu.model.name, os, abi});
}

fn addConfigOptions(b: *std.Build, mod: *std.Build.Module, buildOptions: anytype,
  optimize: std.builtin.OptimizeMode, logLevel: std.log.Level) !void {
  // Add all the build options as code options. These options can be passed
  // into and used by target Zig application/library code
  const codeOptions = b.addOptions();
  codeOptions.addOption([]const u8, "target", buildTargetString);
  codeOptions.addOption([]const u8, "gitHash", buildOptions.gitHash);
  codeOptions.addOption([]const u8, "version", zon.version);
  codeOptions.addOption(u64, "fingerPrint", zon.fingerprint);
  codeOptions.addOption([]const u8, "buildDate", buildOptions.buildDate);
  codeOptions.addOption([]const u8, "buildOs", buildOptions.buildOs);
  codeOptions.addOption([]const u8, "buildHost", buildOptions.buildHost);
  codeOptions.addOption(std.log.Level, "logLevel", logLevel);
  codeOptions.addOption(std.builtin.OptimizeMode, "optimize", optimize);
  mod.addOptions("config", codeOptions);
}

fn addExternalLib(b: *std.Build, disableAssert: bool, optimize: std.builtin.OptimizeMode,
  logLevel: std.log.Level, target: std.Build.ResolvedTarget, name: []const u8,
  suffix: []const u8) !*std.Build.Step.Compile {

  const lib = b.addLibrary(
    .{
      .name = try concat(b, name, suffix, ""),
      .linkage = .static,
      .root_module = b.createModule(
        .{
          .root_source_file = b.path("src/ext.zig"),
          .target = target,
          .optimize = optimize,
        }
      ),
    }
  );

  lib.root_module.addCSourceFile(
    .{
      .file = b.path("ext/src/io.cpp"),
      .flags = &.{""},
      .language = std.Build.Module.CSourceLanguage.cpp,
    }
  );
  lib.root_module.addCSourceFile(
    .{
      .file = b.path("ext/src/curl.cpp"),
      .flags = &.{""},
      .language = std.Build.Module.CSourceLanguage.cpp,
    }
  );
  lib.root_module.addCSourceFile(
    .{
      .file = b.path("ext/src/thread.cpp"),
      .flags = &.{""},
      .language = std.Build.Module.CSourceLanguage.cpp,
    }
  );
  lib.root_module.addCSourceFile(
    .{
      .file = b.path("ext/src/memory.cpp"),
      .flags = &.{""},
      .language = std.Build.Module.CSourceLanguage.cpp,
    }
  );
  lib.root_module.addCSourceFile(
    .{
      .file = b.path("ext/src/json.cpp"),
      .flags = &.{""},
      .language = std.Build.Module.CSourceLanguage.cpp,
    }
  );
  lib.root_module.addCSourceFile(
    .{
      .file = b.path("ext/src/simdjson/simdjson.cpp"),
      .flags = &.{""},
      .language = std.Build.Module.CSourceLanguage.cpp,
    }
  );

  lib.root_module.addIncludePath(b.path("ext/src"));
  lib.root_module.addIncludePath(b.path("ext/src/simdjson"));
  lib.root_module.addIncludePath(b.path("ext/src/stringzilla"));
  lib.root_module.addIncludePath(b.path("ext/src/zlib"));

  if (disableAssert) {
    lib.root_module.addCMacro("NDEBUG", "1");
  }
  lib.root_module.addCMacro("SIMDJSON_AVX512_ALLOWED", "0");
  lib.root_module.addCMacro("SIMDJSON_IMPLEMENTATION_HASWELL", "1");
  lib.root_module.addCMacro("SIMDJSON_EXCEPTIONS", "0");
  lib.root_module.addCMacro("SIMDJSON_THREADS_ENABLED", "0");
  lib.root_module.addCMacro("SZ_USE_HASWELL", "1");
  lib.root_module.addCMacro("SZ_AVOID_LIBC", "0");
  lib.root_module.addCMacro("INFINITECH_LOG_LEVEL", externLibLogLevel[@intFromEnum(logLevel)]);
  lib.root_module.addCMacro("_LARGEFILE64_SOURCE", "1");
  lib.root_module.addCMacro("HAVE_HIDDEN", "1");
 
  lib.root_module.link_libcpp = true;

  b.installArtifact(lib);

  return lib;
}

fn addTask(b: *std.Build, optimize: std.builtin.OptimizeMode,
  target: std.Build.ResolvedTarget, extLib: ?*std.Build.Step.Compile,
  binder: ?*std.Build.Step.TranslateC, baseName: []const u8,
  suffix: []const u8, logLevel: std.log.Level, buildOptions: anytype) !void {

  const exeFqn = try concat(b, baseName, suffix, "");
  const modFqn = try concat(b, "module", exeFqn, ".");
  const modPath = try makePath(b, "src/", baseName, ".zig");
  const sourcePath = try makePath(b, "src/task/", baseName, "/main.zig");

  // Executable module
  const mod = b.addModule(modFqn,
    .{
      .root_source_file = b.path(modPath),
      .target = target,
      .optimize = optimize,
    }
  );
  try addConfigOptions(b, mod, buildOptions, optimize, logLevel);

  if (binder) |ptr| {
    mod.addImport("binding_c", ptr.createModule());
  }

  // Executable
  const exe = b.addExecutable(.{
    .name = exeFqn,
    .root_module = b.createModule(.{
      .root_source_file = b.path(sourcePath),
      .target = target,
      .optimize = optimize,
      .imports = &.{
        .{.name = baseName, .module = mod},
      },
    }),
  });

  // Link extLib if requested
  if (extLib) |lib| {
    exe.root_module.linkLibrary(lib);
  }

  b.installArtifact(exe);
  const targetDescription = try concat(b, "run", exeFqn, " ");
  const artifact = b.addRunArtifact(exe);
  const runStep = b.step(exeFqn, targetDescription);
  runStep.dependOn(&artifact.step);
}

pub fn build(b: *std.Build) !void {
  // Can build on host's compiler?
  isCompilerValid();

  // Build target
  const buildTarget = b.standardTargetOptions(.{});
  // Build target as pretty printed string
  try makeBuildTargetString(b, buildTarget.result);

  // Options all code shares
  const buildOptions = .{
    .gitHash = b.option(
      []const u8,
      "gitHash",
      "git commit default last commitId",
    ) orelse std.mem.trimEnd(u8, b.run(&.{ "git", "rev-parse", "--verify", "HEAD" }), "\n"),
    .buildDate = b.option(
      []const u8,
      "buildDate",
      "build date default 'date -u'",
    ) orelse std.mem.trimEnd(u8, b.run(&.{ "date", "-u"}), "\n"),
    .buildOs = b.option(
      []const u8,
      "buildOs",
      "OS version of build machine default 'cat /proc/version'",
    ) orelse std.mem.trimEnd(u8, b.run(&.{ "cat", "/proc/version"}), "\n"),
    .buildHost = b.option(
      []const u8,
      "buildHost",
      "build machine hostname default bash 'hostname'",
    ) orelse std.mem.trimEnd(u8, b.run(&.{ "hostname"}), "\n"),
    .logLevel  = b.option(
      std.log.Level,
      "logLevel",
      "logging level default 'WARN'",
    )
  };

  // Translate C-bindings in all build variations
  var i: usize = 0;
  while (i<externLib.len) {
    const opt: std.builtin.OptimizeMode = @enumFromInt(i);
    var logLevel = defaultLogLevel[i];
    if (buildOptions.logLevel) |cmdLineDefault| {
      logLevel = cmdLineDefault;
    }
    bindingc[i] = b.addTranslateC(.{
      .root_source_file = b.path("ext/src/binding.h"),
      .target = buildTarget,
      .optimize = opt,
    });
    bindingc[i].addIncludePath(b.path("ext/src"));
    bindingc[i].linkSystemLibrary("curl", .{});
    bindingc[i].linkSystemLibrary("zlib", .{});
    i=i+1;
  }

  // Add library for external code in all build variations
  i = 0;
  while (i<externLib.len) {
    const opt: std.builtin.OptimizeMode = @enumFromInt(i);
    const disableAssert = (i>=2);
    var logLevel = defaultLogLevel[i];
    if (buildOptions.logLevel) |cmdLineDefault| {
      logLevel = cmdLineDefault;
    }
    const ptr = try addExternalLib(b, disableAssert, opt, logLevel,
      buildTarget, "libext", optSuffix[i]);
    externLib[i] = ptr;
    i=i+1;
  }

  // Add all tasks in all build variations
  i = 0;
  while (i<externLib.len) {
    const opt: std.builtin.OptimizeMode = @enumFromInt(i);
    var logLevel = defaultLogLevel[i];
    if (buildOptions.logLevel) |cmdLineDefault| {
      logLevel = cmdLineDefault;
    }
    try addTask(b, opt, buildTarget, externLib[i], bindingc[i], "download_zip", optSuffix[i], logLevel, buildOptions);
    i=i+1;
  }
}
