package;

typedef SwagSection =
{
	var sectionNotes:Array<Dynamic>;
	var sectionBeats:Float;
	var lengthInSteps:Int;
	var typeOfSection:Int;
	var mustHitSection:Bool;
	var gfSection:Bool;
	var bpm:Float;
	var changeBPM:Bool;
	var altAnim:Bool;
	var bfAltAnim:Bool;
	var dType:Int;
	var dadCrossfade:Bool;
	var bfCrossfade:Bool;
}

class Section
{
	public var sectionNotes:Array<Dynamic> = [];

	public var sectionBeats:Float = 4;
	public var lengthInSteps:Int = 16;
	public var gfSection:Bool = false;
	public var typeOfSection:Int = 0;
	public var mustHitSection:Bool = true;
	public var dadCrossfade:Bool = false;
	public var bfCrossfade:Bool = false;
	public var dType:Int = 0;

	/**
	 *	Copies the first section into the second section!
	 */
	public static var COPYCAT:Int = 0;

	public function new(lengthInSteps:Int = 16, ?sectionBeats:Int = 4)
	{
		this.lengthInSteps = lengthInSteps;
		this.sectionBeats = sectionBeats;
	}
}
