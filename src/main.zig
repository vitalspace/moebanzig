const std = @import("std");
const bn = @import("binarySearch.zig");

pub const Moeban = struct {
    db_name: []const u8,
    db_content: []const u8,
    allocator: std.mem.Allocator,

    fn init(db_name: []const u8, allocator: std.mem.Allocator) !Moeban {
        if (!try existsDataBase(db_name)) {
            try createDataBase(db_name, "{}");
        } else {
            return .{ .db_name = db_name, .allocator = allocator, .db_content = try readDataBase(db_name, allocator) };
        }
        return error.NoSePudoInstanciar;
    }

    fn deinit(this: @This()) void {
        this.allocator.free(this.db_content);
    }

    fn createDataBase(db_name: []const u8, content: []const u8) !void {
        const file = std.fs.cwd().createFile(db_name, .{}) catch |err| {
            std.debug.print("Could not create database Err: {}\n", .{err});
            return;
        };
        defer file.close();

        file.writeAll(content) catch |err| {
            std.debug.print("Could not write to database Err: {}\n ", .{err});
            return;
        };
        std.debug.print("Database \"{s}\" was created\n", .{db_name});
    }

    fn existsDataBase(db_name: []const u8) !bool {
        std.fs.cwd().access(db_name, .{ .mode = .read_only }) catch |err| {
            if (err == error.FileNotFound) {
                return false;
            }
        };
        return true;
    }

    fn readDataBase(db_name: []const u8, allocator: std.mem.Allocator) ![]const u8 {
        const file = std.fs.cwd().readFileAlloc(allocator, db_name, std.math.maxInt(usize)) catch |err| {
            std.debug.print("Could not read database Err: {}\n", .{err});
            return err;
        };
        return file;
    }

    pub fn model(this: @This(), comptime model_name: []const u8) !Model {
        const parsed = std.json.parseFromSlice(std.json.Value, this.allocator, this.db_content, .{}) catch unreachable;
        const modelInstance = Model{ .db = this, .model_name = model_name, .object = parsed, .allocator = this.allocator };
        return modelInstance;
    }
};

pub const Model = struct {
    db: Moeban,
    model_name: []const u8,
    object: std.json.Parsed(std.json.Value),
    // object: std.json.Value,
    allocator: std.mem.Allocator,

    fn stringify(this: @This(), object: std.json.Parsed(std.json.Value)) ![]const u8 {
        const str = try std.json.stringifyAlloc(this.allocator, object.value.object.get(this.model_name).?, .{ .whitespace = .indent_2 });
        defer this.allocator.free(str);

        var str_copy = try this.allocator.alloc(u8, str.len);
        std.mem.copy(u8, str_copy, str);

        return str_copy;
    }

    pub fn find(this: @This()) ![]const u8 {
        const object = this.object;
        const str_copy = try this.stringify(object);
        return str_copy;
    }

    pub fn findOne(this: @This(), comptime key: anytype, comptime target: anytype) ![]const u8 {
        const object = this.object;
        var items = object.value.object.get(this.model_name).?.array.items;
        const searchResult = bn.BinarySearch{ .items = items, .key = key, .target = target };
        std.mem.sort(std.json.Value, items, searchResult, bn.BinarySearch.compareById);

        switch (@typeInfo(@TypeOf(target))) {
            .ComptimeInt => {
                const item = searchResult.searchById();
                const result = try std.json.stringifyAlloc(this.allocator, items[item.?], .{ .whitespace = .indent_2 });
                return result;
            },
            .Pointer => {
                std.debug.print("puta cadena", .{});
                return "alv";
            },
            .Bool => {
                // manejar int
                std.debug.print("es un boleano pa\n", .{});
            },
            else => {
                std.debug.print("No podemos validar este tipo de dato\n", .{});
                // manejar otros tipos
            },
        }
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var allocator = gpa.allocator();

    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) {
            std.debug.print("memory leak \n", .{});
        }
    }

    const db = try Moeban.init("test.json", allocator);
    defer db.deinit();

    const user = try db.model("users");
    defer user.object.deinit();

    const str = try user.find();
    defer allocator.free(str);
    // std.debug.print("{s}\n", .{str});

    const find = try user.findOne("age", 23);
    defer allocator.free(find);
    std.debug.print("{s}\n", .{find});
}
