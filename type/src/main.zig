const std = @import("std");

pub const Limit = enum(u64) {
  SHA256_ASCII_SIZE = 64,
  UTC_TIMESTAMP_ASCII_SIZE = 28,
};

pub const FileType = enum(u16) {
  JSON,
};

pub const CompressionType = enum(u16) {
  ZIP,
};

pub const FileSourceMethod = enum(u8) {
  // Relative to Infinitech we pull the file by CURL/SFTP
  PULL,
  // Relative to Infinitech counterparty pushes file to us onto our file system
  PUSH,
};

pub const URL = struct {
  URL: []const u8,

  pub fn verify(self: URL) bool {
    return self.URL.len()>0;
  }
};

pub const FileManifest = struct {
  SizeBytes: u64,
  FileType: FileType,
  Name: []const u8,
  Sha256: []const u8,
  StorageURL: ?[]URL,

  pub fn verify(self: FileManifest) bool {
    var ok =
      self.SizeBytes>0 and
      self.Name.len()>0 and
      self.Sha256.len()==Limit.SHA256_ASCII_SIZE;
    if (self.StorageURL) |list| {
      for (list) |item| { 
        ok = ok and item.verify();
      }
    }
  }
};

pub const CompressedFileManifest = struct {
  SizeBytes: u64,
  CompressMethod: CompressionType,
  Name: []const u8,
  Sha256: []const u8,
  StorageURL: ?[]URL,
  Contents: []FileManifest,

  pub fn verify(self: CompressedFileManifest) bool {
    var ok = 
      self.SizeBytes>0 and
      self.Name.len()>0 and
      self.Sha256.len()==Limit.SHA256_ASCII_SIZE and
      self.Contents.len()>0;
    if (self.StorageURL) |list| {
      for (list) |item| { 
        ok = ok and item.verify();
      }
    }
    for (self.Contents) |value| {
      ok = ok and value.verify();
    }
    return ok;
  }
};

const PullFileEvent = struct {
  URL: []const u8,
  BeginDownloadTimestampUTC: []const u8,
  EndDownloadTimestampUTC: []const u8,
  File: ?FileManifest,
  CompressFile: ?CompressedFileManifest,

  pub fn verify(self: PullFileEvent) bool {
    var ok =
      self.URL.len()>0 and
      self.BeginDownloadTimestampUTC.len()==Limit.UTC_TIMESTAMP_ASCII_SIZE and
      self.EndDownloadTimestampUTC.len()==Limit.UTC_TIMESTAMP_ASCII_SIZE;
    var hasFile = false;
    if (self.File) |file| {
      hasFile = true;
      ok = ok and file.verify();
    }
    var hasCompressFile = false; 
    if (self.CompressFile) |file| {
      hasCompressFile = true;
      ok = ok and file.verify();
    }
    if ((hasFile==false and hasCompressFile==false) or (hasFile==true and hasCompressFile==true)) {
      ok = ok and false;
    }
    return ok;
  }
};

pub fn main() !void {
  return;
}
