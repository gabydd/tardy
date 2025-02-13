const std = @import("std");
const assert = std.debug.assert;

/// Wraps the given value into a specified integer type.
/// The value must fit within the size of the given I.
/// I is usually a usize.
pub fn wrap(comptime I: type, value: anytype) I {
    assert(@typeInfo(I) == .int);
    assert(@typeInfo(I).int.signedness == .unsigned);

    return context: {
        switch (comptime @typeInfo(@TypeOf(value))) {
            .pointer => break :context @intFromPtr(value),
            .void => break :context 1,
            .int => |int_info| {
                comptime assert(int_info.bits <= @bitSizeOf(usize));
                const uint = @Type(std.builtin.Type{
                    .int = .{
                        .signedness = .unsigned,
                        .bits = int_info.bits,
                    },
                });

                break :context @intCast(@as(uint, @bitCast(value)));
            },
            .@"struct" => |struct_info| {
                comptime assert(@bitSizeOf(struct_info.backing_integer.?) <= @bitSizeOf(usize));
                const uint = @Type(std.builtin.Type{
                    .int = .{
                        .signedness = .unsigned,
                        .bits = @bitSizeOf(struct_info.backing_integer.?),
                    },
                });

                break :context @intCast(@as(uint, @bitCast(value)));
            },
            else => unreachable,
        }
    };
}

/// Unwraps a specified type from an underlying value.
/// The value must be an unsigned integer type, typically a usize.
pub fn unwrap(comptime T: type, value: anytype) T {
    const I = @TypeOf(value);
    assert(@typeInfo(I) == .int);
    assert(@typeInfo(I).int.signedness == .unsigned);

    return context: {
        switch (comptime @typeInfo(T)) {
            .pointer => break :context @ptrFromInt(value),
            .void => break :context {},
            .int => |int_info| {
                const uint = @Type(std.builtin.Type{
                    .int = .{
                        .signedness = .unsigned,
                        .bits = int_info.bits,
                    },
                });

                break :context @bitCast(@as(uint, @truncate(value)));
            },
            .@"struct" => |struct_info| {
                const uint = @Type(std.builtin.Type{
                    .int = .{
                        .signedness = .unsigned,
                        .bits = @bitSizeOf(struct_info.backing_integer.?),
                    },
                });

                break :context @bitCast(@as(uint, @truncate(value)));
            },
            else => unreachable,
        }
    };
}
