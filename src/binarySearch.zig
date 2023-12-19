const std = @import("std");

pub const BinarySearch = struct {
    items: []std.json.Value,
    key: []const u8,

    pub fn searchByInt(this: @This(), comptime target: anytype) ?usize {
        var left: usize = 0;
        var right = this.items.len;

        while (left < right) {
            const mid = left + (right - left) / 2;
            if (this.items[mid].object.get(this.key).?.integer == target) {
                return mid;
            } else if (this.items[mid].object.get(this.key).?.integer < target) {
                left = mid + 1;
            } else {
                right = mid;
            }
        }
        return null;
    }

    pub fn searchByString(this: @This(), comptime target: anytype) ?usize {
        var left: usize = 0;
        var right = this.items.len;

        while (left < right) {
            const mid = left + (right - left) / 2;
            const comparison = compareByString(this.items[mid].object.get(this.key).?.string, target);

            if (comparison == 0) {
                return mid;
            } else if (comparison < 0) {
                left = mid + 1;
            } else {
                right = mid;
            }
        }
        return null;
    }

    fn compareByString(item: []const u8, target: []const u8) i32 {
        if (std.mem.eql(u8, item, target)) {
            return 0;
        } else if (std.mem.lessThan(u8, item, target)) {
            return -1;
        } else {
            return 1;
        }
    }

    pub fn compareObjectsByStrings(this: @This(), a: std.json.Value, b: std.json.Value) bool {
        return std.mem.lessThan(u8, a.object.get(this.key).?.string, b.object.get(this.key).?.string);
    }

    pub fn compareById(this: @This(), a: std.json.Value, b: std.json.Value) bool {
        return a.object.get(this.key).?.integer < b.object.get(this.key).?.integer;
    }
};
