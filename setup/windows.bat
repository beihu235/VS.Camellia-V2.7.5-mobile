@echo off
color 0a
cd ..
@echo on
echo Installing dependencies...
echo This might take a few moments depending on your internet speed.
haxelib install lime 8.1.2 --quiet
haxelib install flixel-addons 3.0.2 --quiet
haxelib install openfl 9.3.3 --quiet
haxelib install flixel 5.5.0 --quiet
haxelib git hscript-iris https://github.com/crowplexus/hscript-iris --quiet
haxelib git flixel-animate https://github.com/MaybeMaru/flixel-animate --quiet
haxelib git moonchart https://github.com/MaybeMaru/moonchart --quiet
haxelib install hxvlc 1.9.2 --quiet
haxelib install hxcpp 4.3.2 --quiet
haxelib install hxdiscord_rpc 1.2.4 --quiet
haxelib install hxjson5 --quiet
echo Finished!
pause
