## 3.0.0
* Merged awesome controller implementation from jeanmatthieud that solves many bugs in cases where widget is not available (braking change)
* Fixed problems when writing too fast
* Fixed conflict between scrolling scroll container and drawing the signature

Migration from 2.x.x:
* You have to provide SignatureController and use it to manipulate with data instead using widget itself. Api is almost same but it is now split between ``Signature`` widget and ``SignatureController``.
* See updated [example](example). 

## 2.0.1
* Fixed null pointer in case that future was resolved after widget has been removed from tree on slower devices

## 2.0.0

* Migration from ```android.support``` packages to ```androidx``` packages that allows this library to be used with flutter projects that use ```androidx```. If you need to stay on ```android.support``` for whatever reason, don't upgrade as it may break your build. [See more](https://flutter.io/docs/development/packages-and-plugins/androidx-compatibility).  

## 1.1.0
* Fixed breaking change in Picture.toImage in latest flutter
* New properties isEmpty and isNotEmpty at Signature class for validation purposes

## 1.0.3

* fixed bug where canvas was not writable in case of specific boundary setup

## 1.0.2

* removed debug statements and cleanup

## 1.0.1

* README modifications and code reformat

## 1.0.0

* Initial release