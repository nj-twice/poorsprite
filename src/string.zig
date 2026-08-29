const std = @import("std");

const StringError = error{ TooShort, NoSuffix };

pub fn removeSuffix(input: []const u8) StringError![]const u8 {
    var dot_pos = input.len;
    while (dot_pos > 0) {
        dot_pos -= 1;
        if (input[dot_pos] == '.') break;
    }
    if (dot_pos < 1) return StringError.NoSuffix;

    return input[0..dot_pos];
}

test removeSuffix {
    const f = removeSuffix;

    const s1 = "Wow.jpeg";
    const r1 = "Wow";
    const s2 = "Hello1.png";
    const r2 = "Hello1";
    const s3 = ".gif";
    const r3 = StringError.NoSuffix;
    const s4 = "o.mp3";
    const r4 = "o";
    const s5 = "there.are.multiple.endings";
    const r5 = "there.are.multiple";
    const s6 = "noway";
    const r6 = StringError.NoSuffix;

    try std.testing.expectEqualSlices(u8, r1, f(s1) catch unreachable);
    try std.testing.expectEqualSlices(u8, r2, f(s2) catch unreachable);
    try std.testing.expectEqual(r3, f(s3));
    try std.testing.expectEqualSlices(u8, r4, f(s4) catch unreachable);
    try std.testing.expectEqualSlices(u8, r5, f(s5) catch unreachable);
    try std.testing.expectEqual(r6, f(s6));
}

pub fn getLastFourChars(input: []const u8) StringError![]const u8 {
    if (input.len < 4) return StringError.TooShort;
    const len = input.len;

    const output: []const u8 = input[len - 4 .. len];
    return output;
}

test getLastFourChars {
    const string1 = "Hello, are you here?";
    const result1 = "ere?";
    const string2 = "Hi";
    const result2 = StringError.TooShort;
    const string3 = "OJpjdwx";
    const result3 = "jdwx";
    try std.testing.expectEqualSlices(
        u8,
        result1,
        getLastFourChars(string1) catch unreachable,
    );
    try std.testing.expectEqual(
        result2,
        getLastFourChars(string2),
    );
    try std.testing.expectEqualSlices(
        u8,
        result3,
        getLastFourChars(string3) catch unreachable,
    );
}
