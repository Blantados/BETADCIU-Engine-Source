package luafiles;

import flixel.addons.display.FlxBackdrop;

class ModchartBackdrop extends FlxBackdrop
{
	public var wasAdded:Bool = false;
	public var animOffsets:Map<String, Array<Float>> = new Map<String, Array<Float>>();
	public var animPrefixes:Map<String, String> = new Map<String, String>();
	//public var isInFront:Bool = false;
}