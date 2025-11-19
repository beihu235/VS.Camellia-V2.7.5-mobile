package funkin.backend;

class EventHandler {
    public dynamic function triggered(event:Event) {}
	public dynamic function pushed(event:Event) {}

	// just so it doesn't yell at me
	public function new() {}

    public var list:Array<Event> = [];
    public var index:ShortInt = 0;
    public function load(song:String):EventHandler {
        // has to be per song instead
        // because of sm/osu support
        if (!Paths.exists('songs/$song/events.json')) return this;

        list.resize(0);

        final data = Json5.parse(Paths.getFileContent('songs/$song/events.json'));
		var events:Array<{name:String, time:Float, args:Array<Dynamic>}> = data.list;
		for (i => event in events) {
			var eventToPush:Event = {
				name: event.name,
				time: event.time,
				args: event.args
			};
			list.push(eventToPush);
			pushed(eventToPush);
        }

        index = 0;
		list.sort((a, b) -> return Std.int(a.time - b.time));

		return this;
    }

    public function update():Void {
        if (index >= list.length) return;

        final nextEvent:Event = list[index];
        if (nextEvent.time > Conductor.rawTime - Conductor.offset) return;
        triggered(nextEvent);
        index++;
    }
}

@:structInit 
class Event {
    public var name:String = '';
    public var time:Float = 0.0;
    public var args:Array<Dynamic> = [];

	public function toString():String {
		return 'Name: $name | Time: $time | Arguments: $args';
	}
}