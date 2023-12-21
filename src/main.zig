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
        const searchResult = bn.BinarySearch{ .items = items, .key = key };

        switch (@typeInfo(@TypeOf(target))) {
            .ComptimeInt => {
                std.mem.sort(std.json.Value, items, searchResult, bn.BinarySearch.compareById);
                const item = searchResult.searchByInt(target);
                if (item == null) return error.ObjectDoesNotExists;
                const result = try std.json.stringifyAlloc(this.allocator, items[item.?], .{ .whitespace = .indent_2 });
                return result;
            },
            .Pointer => {
                std.mem.sort(std.json.Value, items, searchResult, bn.BinarySearch.compareObjectsByStrings);
                const item = searchResult.searchByString(target);
                if (item == null) return error.ObjectDoesNotExists;
                const result = try std.json.stringifyAlloc(this.allocator, items[item.?], .{ .whitespace = .indent_2 });
                return result;
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

    pub fn getValueString(this: @This(), jsonString: []const u8, key: []const u8) ![]const u8 {
        const value = try std.json.parseFromSlice(std.json.Value, this.allocator, jsonString, .{});
        defer value.deinit();

        const result = value.value.object.get(key) orelse return error.KeyNotFound;
        const result_str = try this.allocator.alloc(u8, result.string.len);
        std.mem.copy(u8, result_str, result.string);
        return result_str;
    }

    pub fn getValueInt(this: @This(), jsonString: []const u8, key: []const u8) !i64 {
        const value = try std.json.parseFromSlice(std.json.Value, this.allocator, jsonString, .{});
        defer value.deinit();

        const result = value.value.object.get(key) orelse return error.KeyNotFound;
        return result.integer;
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

    const obj = try user.findOne("name", "ivan");
    defer allocator.free(obj);
    std.debug.print("{s}\n", .{obj});

    const name = try user.getValueString(obj, "name");
    defer allocator.free(name);
    std.debug.print("{s}\n", .{name});

    const id = try user.getValueInt(obj, "id");
    std.debug.print("{d}\n", .{id});

    const age = try user.getValueInt(obj, "age");
    std.debug.print("{d}\n", .{age});
}
