package funkin.backend;

import flixel.FlxG;
import flixel.input.touch.FlxTouch;
import flixel.math.FlxRect;
import haxe.ds.StringMap;

class MobileInputAdapter {
    public var areas:StringMap<FlxRect>;

    public function new() {
        areas = new StringMap<FlxRect>();
        #if mobile
        var w = FlxG.width;
        var h = FlxG.height;
        var y = Std.int(h * 0.6);
        var col = Std.int(w / 4);
        areas.set("note_left", FlxRect.get(0, y, col, h - y));
        areas.set("note_down", FlxRect.get(col, y, col, h - y));
        areas.set("note_up", FlxRect.get(col * 2, y, col, h - y));
        areas.set("note_right", FlxRect.get(col * 3, y, w - col * 3, h - y));
        areas.set("ui_left", FlxRect.get(0, 0, Std.int(w * 0.5), Std.int(h * 0.4)));
        areas.set("ui_right", FlxRect.get(Std.int(w * 0.5), 0, Std.int(w * 0.5), Std.int(h * 0.4)));
        areas.set("ui_up", FlxRect.get(0, 0, w, Std.int(h * 0.2)));
        areas.set("ui_down", FlxRect.get(0, Std.int(h * 0.4), w, Std.int(h * 0.2)));
        #end
    }

    public function setArea(action:String, rect:FlxRect):Void {
        areas.set(action, rect);
    }

    public inline function pressed(action:String):Bool {
        #if mobile
        var r = areas.get(action);
        if (r == null) return false;
        for (t in FlxG.touches.list) {
            var x = Std.int(t.screenX);
            var y = Std.int(t.screenY);
            if (x >= r.x && y >= r.y && x < r.x + r.width && y < r.y + r.height) return true;
        }
        #end
        return false;
    }

    public inline function justPressed(action:String):Bool {
        #if mobile
        var r = areas.get(action);
        if (r == null) return false;
        for (t in FlxG.touches.list) {
            if (!t.justPressed) continue;
            var x = Std.int(t.screenX);
            var y = Std.int(t.screenY);
            if (x >= r.x && y >= r.y && x < r.x + r.width && y < r.y + r.height) return true;
        }
        #end
        return false;
    }

    public inline function justReleased(action:String):Bool {
        #if mobile
        var r = areas.get(action);
        if (r == null) return false;
        for (t in FlxG.touches.list) {
            if (!t.justReleased) continue;
            var x = Std.int(t.screenX);
            var y = Std.int(t.screenY);
            if (x >= r.x && y >= r.y && x < r.x + r.width && y < r.y + r.height) return true;
        }
        #end
        return false;
    }

    public inline function anyPressed():Bool {
        #if mobile
        for (t in FlxG.touches.list) if (t.pressed) return true;
        #end
        return false;
    }

    public inline function anyJustPressed():Bool {
        #if mobile
        for (t in FlxG.touches.list) if (t.justPressed) return true;
        #end
        return false;
    }

    public inline function anyJustReleased():Bool {
        #if mobile
        for (t in FlxG.touches.list) if (t.justReleased) return true;
        #end
        return false;
    }
}