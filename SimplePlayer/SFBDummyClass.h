//
// SPDX-FileCopyrightText: 2020 Stephen F. Booth <contact@sbooth.dev>
// SPDX-License-Identifier: MIT
//
// Part of https://github.com/sbooth/SimplePlayer-macOS
//

@import Foundation;

/// This class only exists so SimplePlayer won't be a pure Swift executable, making ubsan available for debugging SFBAudioEngine
@interface SFBDummyClass : NSObject
@end
