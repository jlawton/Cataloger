Cataloger
=========

`cataloger` is a simple utility for creating constants from framework assets.

This has a few potential benefits, including:

 * if you add and remove assets, you can keep your code up-to-date with a `cataloger` build phase.
 * you get compile errors for invalid asset names, and autocompletion of valid names.
 * it's easy to expose your assets to consumers outside of your framework.

Usage
-----

Create a Swift file describing the assets in an asset catalog. Once a catalog has been compiled, it is opaque. Apple has not published the format of a `.car` and I'm not interested in figuring it out, since the source folder is a much simpler route to the same information.

```
$ cataloger generate <path/to/Images.xcassets>
```

Create a Swift file describing the assets in a framework.

```
$ cataloger generate <path/to/Framework.framework>
```

Options
-------

There are a few command line options currently available. For example:

```
$ cataloger generate \
    --name 'SomeFrameworkAsset' \
    --type 'enum' \
    --bundle-class 'SomeFrameworkClass' \
    path/to/Images.xcassets
```

This would define a String-backed Swift enum, named `SomeFrameworkAsset`, with cases for the image assets found in `path/to/Images.xcassets`. It would also generate an image accessor, which looks up the assets in the in which the class `SomeFrameworkClass` is defined.

See `cataloger help generate` for more details.

Name Mangling
-------------

`cataloger` takes the names of assets and turns them into Swift constants. It's not very intelligent about this right now, but should work for common naming schemes.

For instance, an image which you would normally load with:

```swift
let icon = UIImage(named: "icon/friendly_face", in: Bundle(for: SomeFrameworkClass.self), compatibleWith: nil)!
```

might be accessed like:

```swift
let icon = SomeFrameworkAsset.iconFriendlyFace.image
```

Limitations
-----------

Currently, `cataloger` only really handles image assets. It is in early development, and there are useful features yet to be implemented.
