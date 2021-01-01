pub fn iteratorToSlice(iter: anytype, allocator: *Allocator) ![]@TypeOf(iter.next().?) {
    var list = std.ArrayList(@TypeOf(iter.next().?)).init(allocator);
    errdefer list.deinit();
    while (iter.next()) |item| {
        try list.append(item);
    }
    return list.toOwnedSlice();
}
