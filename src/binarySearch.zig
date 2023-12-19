const std = @import("std");

pub const BinarySearch = struct {
    items: []std.json.Value,
    key: []const u8,
    target: i32,

    pub fn searchById(this: @This()) ?usize {
        var left: usize = 0;
        var right = this.items.len;

        while (left < right) {
            const mid = left + (right - left) / 2;
            if (this.items[mid].object.get(this.key).?.integer == this.target) {
                return mid;
            } else if (this.items[mid].object.get(this.key).?.integer < this.target) {
                left = mid + 1;
            } else {
                right = mid;
            }
        }
        return null;
    }

    pub fn compareById(this: @This(), a: std.json.Value, b: std.json.Value) bool {
        return a.object.get(this.key).?.integer < b.object.get(this.key).?.integer;
    }
};
