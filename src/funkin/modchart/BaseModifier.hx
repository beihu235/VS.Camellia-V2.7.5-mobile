package funkin.modchart;

import funkin.objects.PlayField;
import funkin.objects.Strumline;
import funkin.modchart.ModchartManager;
import funkin.objects.FunkinSprite;

/*@:structInit class SetPrep {
	public var strumline:Int;
	public var index:Int;
	public var value:Float;
}*/

class BaseModifier {
	var parent:ModchartManager;
	
	var grandparent(get, null):PlayField; // funny
	function get_grandparent()return parent.parent;
	

	public var priority:Int = 0;
	public var active:Array<Bool> = [];
	public var values:Array<Array<Float>> = [];
	public var cacheValues:Array<Array<Float>> = [];

	//public var preppedSets:Array<SetPrep> = [];

	public function new(parent:ModchartManager) {
		this.parent = parent;

		while (active.length < parent.strumlineCount)
			addStrumlineSet();
	}

	/*public function getWithPrep(index:Int, strumline:Int) {
		var i = preppedSets.length - 1;
		while (i >= 0) {
			final prep = preppedSets[i];
			if (prep.index == index && (strumline < 0 || prep.strumline == strumline))
				return prep.value;
			--i;
		}
		return getValue(index, strumline < 0 ? 0 : strumline);
	}*/

	public function getValue(index:Int, strumline:Int) {
		return (strumline < values.length) ? values[strumline][index] : 0;
	}

	public function setValue(index:Int, value:Float, strumline:Int) {
		if (strumline < 0) {
			for (i in 0...values.length)
				values[i][index] = value;
		} else if (strumline < values.length)
			values[strumline][index] = value;

		for (i in 0...active.length)
			active[i] = isActive(values[i]);
	}

	/*public function prepareSet(index:Int, value:Float, strumline:Int) {
		if (strumline < 0) {
			for (i in 0...values.length) {
				final prep:SetPrep = {strumline: i, index: index, value: value};
				preppedSets.push(prep);
			}
		} else {
			final prep:SetPrep = {strumline: strumline, index: index, value: value};
			preppedSets.push(prep);
		}
	}

	public function emptyPreparations() {
		if (preppedSets.length <= 0) return;
		
		for (prep in preppedSets)
			setValue(prep.index, prep.value, prep.strumline);
		preppedSets.splice(0, preppedSets.length);
	}*/

	public function prepare(strumline:Int, beat:Float) {}

	// vv has to return the distance, since you cant pass in pointers
	// only called for notes and sustains, not for strums
	public function adjustDistance(spr:FunkinSprite, distance:Float, unadjustedDistance:Float, beat:Float, lane:Int, strumline:Int, field:Strumline, type:ObjectType): Float {return distance;}
	public function modifiesDistance(strumline:Int) {return false;}

	public function adjustPos(spr:FunkinSprite, pos:Vector3, distance:Float, unadjustedDistance:Float, beat:Float, lane:Int, strumline:Int, field:Strumline, type:ObjectType) {}
	public function modifiesPosition(strumline:Int) {return false;}

	public function adjustScale(spr:FunkinSprite, scale:FlxPoint, distance:Float, beat:Float, lane:Int, strumline:Int, field:Strumline, type:ObjectType) {}
	public function modifiesScale(strumline:Int) {return false;}

	public function adjustVertex(spr:FunkinSprite, vertex:Vector3, pos:Vector3, distance:Float, unadjustedDistance:Float, beat:Float, lane:Int, strumline:Int, field:Strumline, type:ObjectType) {}
	public function modifiesVertex(strumline:Int) {return false;}

	public function getStealth(spr:FunkinSprite, stealth:Float, distance:Float, unadjustedDistance:Float, pos:Vector3, beat:Float, lane:Int, strumline:Int, field:Strumline, type:ObjectType) {return stealth;}
	public function modifiesStealth(strumline:Int) {return false;}

	public function startCache() {
		for (i in 0...cacheValues.length) {
			for (v in 0...values[i].length)
				cacheValues[i][v] = values[i][v];
		}

		while (cacheValues.length < values.length)
			cacheValues.push(values[cacheValues.length].copy());
	}
	public function releaseCache() {
		for (i in 0...cacheValues.length) {
			for (v in 0...cacheValues[i].length)
				values[i][v] = cacheValues[i][v];
		}
	}

	public function addStrumlineSet() {
		active.push(false);
	}

	function isActive(vals:Array<Float>) {
		for (num in vals) {
			if (num != 0.0)
				return true;
		}
		return false;
	}
}