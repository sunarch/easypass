// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

const std = @import("std");

pub fn dieroll() u8 {
    const seed_ts: u128 = @bitCast(std.time.nanoTimestamp());
    const seed: u64 = @truncate(seed_ts);
    var prng = std.rand.DefaultPrng.init(seed);

    const random_value: u64 = prng.next();
    return @truncate(random_value % 6 + 1);
}

test "die roll" {
    const roll = dieroll();
    try std.testing.expect(1 <= roll and roll <= 6);
}
