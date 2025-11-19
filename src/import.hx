#if !macro
// project specific
import funkin.backend.*;
import funkin.backend.Song.Chart;
import funkin.states.*;
import funkin.objects.FunkinSprite;

// flixel specific
import flixel.*;
import flixel.sound.FlxSound;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxColor as FlxColour;
import flixel.util.FlxTimer;
import flixel.util.FlxDestroyUtil;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.group.FlxSpriteGroup;
import flixel.group.FlxGroup;

// haxe
import sys.FileSystem;
import sys.io.File;

// instead of using json5 by default
// we allow both formats to be used
// because although json5 allows for easier readability
// that also hinders its speed
// so in certain circumstances like charts we need to use normal json instead
import hxjson5.Json5;
import haxe.Json;

//kade framework stuff
import openfl.utils.Assets as OpenFlAssets;
import funkin.backend.FlxAudioHandler;
import funkin.backend.audio.FlxAudio;

//these are functions we use a lot, so make them generally available
import funkin.backend.LanguageHandler._t;
import funkin.backend.LanguageHandler._formatT;

// Mobile Controls
import funkin.mobile.objects.MobileControls;
import funkin.mobile.flixel.FlxHitbox;
import funkin.mobile.flixel.FlxVirtualPad;
import funkin.mobile.flixel.input.FlxMobileInputID;
import funkin.mobile.backend.Data;
import funkin.mobile.backend.SUtil;

using StringTools;
#end

import funkin.backend.CPPTypes;



