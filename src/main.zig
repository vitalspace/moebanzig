const std = @import("std");

const User = struct { id: i32, name: []const u8 };

fn Moeban() type {
    return struct {
        db_name: []const u8,
        allocator: std.mem.Allocator,

        fn init(db_name: []const u8, allocator: std.mem.Allocator) !Moeban() {
            if (!try dataBaseExists(db_name)) {
                try createDataBase(db_name, "[]");
            } else {
                const rs = try readDataBase(db_name, allocator);
                std.debug.print("{s}\n", .{rs});
            }
            return .{ .db_name = db_name, .allocator = allocator };
        }

        fn dataBaseExists(db_name: []const u8) !bool {
            std.fs.cwd().access(db_name, .{ .mode = .read_only }) catch |err| {
                if (err == error.FileNotFound) {
                    return false;
                }
            };
            return true;
        }

        fn createDataBase(db_name: []const u8, content: []const u8) !void {
            const file = std.fs.cwd().createFile(db_name, .{ .read = true }) catch |err| {
                std.debug.print("Could not create database Err: {}", .{err});
                return;
            };
            defer file.close();

            file.writeAll(content) catch |err| {
                std.debug.print("Could not write to database Err: {}\n", .{err});
                return;
            };

            std.debug.print("Database \"{s}\" was created.\n", .{db_name});
        }

        fn readDataBase(db_name: []const u8, allocator: std.mem.Allocator) ![]const u8 {
            const file = std.fs.cwd().readFileAlloc(allocator, db_name, std.math.maxInt(usize)) catch |err| {
                std.debug.print("Could not open database Err: {}\n", .{err});
                return err;
            };
            return file;
        }
    };
}

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var db = try Moeban().init("vital.db", allocator);
    _ = db;
}
