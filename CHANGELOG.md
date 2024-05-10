## 5.5.0
* Upgraded gradle plugin
* Changed method for getting parent widget size to prevent drawing outside of the widget
* Fixed exportPenColor being ignored in svg export

## 5.4.1
* Fixed overlapping polylines in svg export (dubydu)
* Fixed problem with svg color representation in some engines (henry2man)

* 
## 5.4.0
* Fixed transparent export background in web
* Ability to disable canvas writting (jeronimocabezuelo)

## 5.3.2
* Ability to initialize width and height of widget with new values (Bungeefan)
* Exposing new information for drawing styles (StrokeCap, StrokeJoin) (saschaernst)
* Export image size for web version (saschaernst)

## 5.3.1
* upgrade to Flutter 3.7
* upgrade dependencies
 
## 5.3.0
* Change `toPngBytes` to have desired width and height parameter, where before having 500x400 as fixed. (yurtemre7) 
* Improve Example project and update it to the latest flutter 3 (yurtemre7)
* Update Readme accordingly (yurtemre7)

## 5.2.1
* Fixed formating of signature.dart to address static analysis on pub.dev

## 5.2.0
* Ability to export image as SVG (h7x4)
* Ability to export image to png with given height and width
  * Drawing will be centered
  * If dimension is smaller than actual drawing in debug mode there will be assertion error 

## 5.1.0
* Fixed broken outside drawing to left and right sides (madsane29)
* Dynamic pressure support (KiritoDv)

## 5.0.1
* If widget was used without dimensions user could draw outside the box. 
* Added exportPenColor

## 5.0.0
* Undo/Redo support (munyaaa)
* onDrawMove callback support (h7x4ABk3g)
* Fixed ```Incorrect use of ParentDataWidget``` error in console under some circumstances. (h7x4ABk3g)

## 4.1.1
* Fixed bug when drawing is cancelled without calling onPointerUp when user touches app bat while drawing (ChannelYu)

## 4.1.0
* Added ``onDrawStart`` and ``onDrawEnd`` callbacks (LukasLiebl)
* Fixed weird multitouch behaviour

## 4.0.2
* Fixed pud.dev analysis issues

## 4.0.1
* Fixed pud.dev analysis issues

## 4.0.0
* Stable release of null safety

## 4.0.0-nullsafety
* Pre release version containing support for dart null safety (tiloc)

## 3.2.1
* Fixed strange dot at the end of the signature when having smaller pen stroke 

## 3.2.0
* Added web support (export was not working in web previously) (leonardarnold)
## 3.1.2
* Fixed not working points setter in ```SignatureController```

## 3.1.1
* Fixed possible null pointer exception (Danvick Miller)

## 3.1.0
* Fixed  bug repainting canvas after clear in some situations (Brian Garcia)
* Added possibility to set export background instead of default transparent (dalosy-projecten-bv)

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