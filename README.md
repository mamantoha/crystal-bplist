# crystal-bplist

Apple's binary property list format implementation in Crystal.

`bplist` module provides an interface for reading and writing the “property list” files used by Apple, primarily on macOS and iOS.
This module supports only binary plist files.

Values can be strings, integers, floats, booleans, arrays, hashes (but only with string keys), `Bytes`, or `Time` objects.

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     bplist:
       github: mamantoha/crystal-bplist
   ```

2. Run `shards install`

## Usage

```crystal
require "bplist"
```

TODO: Write usage instructions here

## Development

TODO: Write development instructions here

## Useful links

- https://medium.com/@karaiskc/understanding-apples-binary-property-list-format-281e6da00dbd
- https://opensource.apple.com/source/CF/CF-635/CFBinaryPList.c.auto.html
- https://docs.python.org/3/library/plistlib.html
- https://github.com/python/cpython/blob/main/Lib/plistlib.py
- http://fileformats.archiveteam.org/wiki/Property_List/Binary

## Contributing

1. Fork it (<https://github.com/mamantoha/crystal-bplist/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Anton Maminov](https://github.com/mamantoha) - creator and maintainer
