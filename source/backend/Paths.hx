package backend;

import flixel.graphics.frames.FlxAtlasFrames;
import openfl.utils.AssetType;
import openfl.utils.Assets as OpenFlAssets;
import openfl.display.BitmapData;
import flixel.graphics.FlxGraphic;
import lime.utils.Assets;
import flash.media.Sound;
import openfl.system.System;
import openfl.geom.Matrix;
import openfl.display.Bitmap;
import openfl.display.PixelSnapping;
import openfl.display3D.textures.Texture;
import haxe.Json;

#if MODS_ALLOWED
import backend.Mods;
#end

using StringTools;

@:access(openfl.display.BitmapData)
class Paths
{
	public static var charPath:Array<String> = [];

	inline public static var SOUND_EXT = #if web "mp3" #else "ogg" #end;

	static var currentLevel:String;

	#if desktop
	public static var ignoreModFolders:Array<String> = [
//		'BETADCIU',
		'characters',
		'custom_events',
		'custom_notetypes',
		'data',
		'songs',
		'music',
		'sounds',
		'videos',
		'images',
		'stages',
		'weeks',
		'fonts',
		'scripts',
		'achievements'
	];
	#end

	static public function setCurrentLevel(name:String)
	{
		currentLevel = name.toLowerCase();
	}

	public static function returnGraphic(key:String, ?library:String = null) 
	{
		if(!currentTrackedAssets.exists(key)) {
			cacheImage(key, library);
		}
		//localTrackedAssets.push(key);
		return currentTrackedAssets.get(key);

		trace('returnGraphic: You failed dipshit! Key '+key+" not found!");
		return null;
	}

	public static function getPath(file:String, type:AssetType, ?library:Null<String> = null, ?modsAllowed:Bool = false)
	{
		#if MODS_ALLOWED
		if(modsAllowed)
		{
			var customFile:String = file;
			if (library != null)
				customFile = '$library/$file';

			var modded:String = modFolders(customFile);
			if(FileSystem.exists(modded)) return modded;
		}
		#end
		
		if (library != null)
			return getLibraryPath(file, library);

		if (currentLevel != null)
		{
			var levelPath:String = '';
			if(currentLevel != 'shared') 
			{
				levelPath = getLibraryPathForce(file, currentLevel);
				if (OpenFlAssets.exists(levelPath, type) || FileSystem.exists(levelPath))
					return levelPath;
			}

			levelPath = getLibraryPathForce(file, "shared");
			if (OpenFlAssets.exists(levelPath, type) || FileSystem.exists(levelPath))
				return levelPath;		
		}

		return getPreloadPath(file);
	}

	static public function getLibraryPath(file:String, library = "preload")
	{
		return if (library == "preload" || library == "default") getPreloadPath(file); else getLibraryPathForce(file, library);
	}

	inline static function getLibraryPathForce(file:String, library:String)
	{
		return '$library:assets/$library/$file';
	}

	inline public static function getPreloadPath(file:String = "")
	{
		return 'assets/$file';
	}

	inline public static function getSharedPath(file:String = '')
	{
		return 'assets/shared/$file';
	}

	inline static public function file(file:String, type:AssetType = TEXT, ?library:String)
	{
		return getPath(file, type, library);
	}

	inline static public function lua(key:String,?library:String)
	{
		if(FileSystem.exists(Paths.modFolders('data/' + key + '.lua')))
			return Paths.modFolders('data/' + key + '.lua');

		return getPath('data/$key.lua', TEXT, library);
	}

	inline static public function lua2(key:String,?library:String)
	{
		if(FileSystem.exists(Paths.modFolders(key +'.lua')))
			return Paths.modFolders(key +'.lua');

		return getPath('$key.lua', TEXT, library);
	}

	inline static public function hx(key:String,?library:String)
	{
		if(FileSystem.exists(Paths.modFolders('data/' + key + '.hx')))
			return Paths.modFolders('data/' + key + '.hx');

		return getPath('data/$key.hx', TEXT, library);
	}

	inline static public function hx2(key:String,?library:String)
	{
		if(FileSystem.exists(Paths.modFolders(key +'.hx')))
			return Paths.modFolders(key +'.hx');

		return getPath('$key.hx', TEXT, library);
	}

	inline static public function stageLua(key:String,?library:String)
	{
		if(FileSystem.exists(Paths.modFolders('stages/' + key + '.lua')) || Assets.exists(Paths.modFolders('stages/' + key + '.lua'))){
			return Paths.modFolders('stages/' + key + '.lua');
		}
		
		return getPath('stages/$key.lua', TEXT, library);
	}

	inline static public function txt(key:String, ?library:String)
	{
		if(FileSystem.exists(Paths.modFolders('data/' + key +'.txt')))
			return Paths.modFolders('data/' + key +'.txt');

		return getPath('data/$key.txt', TEXT, library);
	}

	inline static public function txtNew(key:String, ?library:String)
	{
		if(FileSystem.exists(Paths.modFolders(key +'.txt')))
			return Paths.modFolders(key +'.txt');

		return getPath('$key.txt', TEXT, library);
	}

	inline static public function xmlNew(key:String, ?library:String)
	{
		if(FileSystem.exists(Paths.modFolders(key +'.xml')))
			return Paths.modFolders(key +'.xml');

		return getPath('$key.xml', TEXT, library);
	}

	inline static public function xml(key:String, ?library:String)
	{
		if(FileSystem.exists(Paths.modFolders('data/' + key +'.xml')))
			return Paths.modFolders('data/' + key +'.xml');

		return getPath('data/$key.xml', TEXT, library);
	}

	inline static public function json(key:String, ?library:String)
	{
		if(FileSystem.exists(Paths.modFolders('data/' + key +'.json')))
			return Paths.modFolders('data/' + key +'.json');

		return getPath('data/$key.json', TEXT, library);
	}

	static public function sound(key:String, ?library:String)
	{
		if (FileSystem.exists(Paths.modsSounds('sounds', key)))
		{
			returnSound('sounds', key);
			return Paths.modsSounds('sounds', key);
		}
	
		return getPath('sounds/$key.$SOUND_EXT', SOUND, library);
	}

	inline static public function soundRandom(key:String, min:Int, max:Int, ?library:String)
	{
		return sound(key + FlxG.random.int(min, max), library);
	}

	inline static public function music(key:String, ?library:String):Sound
	{
		var file:Sound = returnSound('music', key, library);
		return file;
	}

	inline static public function video(key:String, ?library:String)
	{
		if(FileSystem.exists(Paths.modFolders('videos/' + key +'.mp4')))
			return Paths.modFolders('videos/' + key +'.mp4');

		return getPath('videos/$key.mp4', BINARY, library);
	}

	inline static public function inst2(song:String, ?library:String)
	{
		var songLowercase = StringTools.replace(song, " ", "-").toLowerCase();
		switch (songLowercase) {
			case 'dad-battle': songLowercase = 'dadbattle';
			case 'philly-nice': songLowercase = 'philly';
		}

		var pre:String = "";
		var suf:String = "";

		if (Main.noCopyright && (Assets.exists('songs:assets/songs/${songLowercase}/'+'Inst'+'Alt'+'.$SOUND_EXT') || FileSystem.exists(Paths.modsSounds('songs', '${songLowercase}/'+pre+'InstAlt'))))
			suf = 'Alt';	
		if (PlayState.isNeonight)
			suf = 'NN';
		if (PlayState.isVitor)		
			suf = 'V';
		if (PlayState.isBETADCIU && CoolUtil.difficulties[0] == "Guest" && (Assets.exists('songs:assets/songs/${songLowercase}/'+'Inst'+'Guest'+'.$SOUND_EXT') || FileSystem.exists(Paths.modsSounds('songs', '${songLowercase}/'+pre+'InstGuest'))))		
			suf = 'Guest';
		if (PlayState.isBETADCIU && (Assets.exists('songs:assets/songs/${songLowercase}/'+'Inst'+'BETADCIU'+'.$SOUND_EXT') || FileSystem.exists(Paths.modsSounds('songs', '${songLowercase}/'+pre+'InstBETADCIU'))))
			suf = 'BETADCIU';

		if (FileSystem.exists(Paths.modsSounds('songs', '${songLowercase}/'+pre+'Inst'+suf)))
		{
			returnSound('songs', '${songLowercase}/'+pre+'Inst'+suf);
			return Paths.modsSounds('songs', '${songLowercase}/'+pre+'Inst'+suf);
		}

		return FileSystem.absolutePath('assets/songs/${songLowercase}/'+pre+'Inst'+suf+'.$SOUND_EXT');
	}

	inline static public function voices2(song:String, postfix:String = null, ?library:String/*this library shit is even used?*/)
	{
		var songLowercase = StringTools.replace(song, " ", "-").toLowerCase();

		var pre:String = "";
		var suf:String = "";

		if (Main.noCopyright && (Assets.exists('songs:assets/songs/${songLowercase}/'+'Voices'+'Alt'+'.$SOUND_EXT') || FileSystem.exists(Paths.modsSounds('songs', '${songLowercase}/'+pre+'VoicesAlt'))))
			suf = 'Alt';		
        if (PlayState.isNeonight)
            suf = 'NN';
        if (PlayState.isVitor)        
            suf = 'V';
        if (PlayState.isBETADCIU && CoolUtil.difficulties[0] == "Guest" && (Assets.exists('songs:assets/songs/${songLowercase}/'+'Voices'+'Guest'+'.$SOUND_EXT') || FileSystem.exists(Paths.modsSounds('songs', '${songLowercase}/'+pre+'VoicesGuest'))))        
            suf = 'Guest';
        if (PlayState.isBETADCIU && (Assets.exists('songs:assets/songs/${songLowercase}/'+'Voices'+'BETADCIU'+'.$SOUND_EXT') || FileSystem.exists(Paths.modsSounds('songs', '${songLowercase}/'+pre+'VoicesBETADCIU'))))
            suf = 'BETADCIU';
        if (postfix != null) suf += '-' + postfix;

        if (FileSystem.exists(Paths.modsSounds('songs', '${songLowercase}/'+pre+'Voices'+suf)))
        {
            returnSound('songs', '${songLowercase}/'+pre+'Voices'+suf);
            return Paths.modsSounds('songs', '${songLowercase}/'+pre+'Voices'+suf);
        }
            
        return FileSystem.absolutePath('assets/songs/${songLowercase}/'+pre+'Voices'+suf+'.$SOUND_EXT');
    }

	inline static public function voices(song:String, ?postfix:String = null)
	{
		var songLowercase = StringTools.replace(song, " ", "-").toLowerCase();
			switch (songLowercase) {
				case 'dad-battle': songLowercase = 'dadbattle';
				case 'philly-nice': songLowercase = 'philly';	
				case 'scary-swings': songLowercase = 'scary swings';
			}

		var pre:String = "";
		var suf:String = "";

		if (PlayState.isNeonight)
			suf = 'NN';
		if (PlayState.isVitor)
			suf = 'V';
		if (PlayState.isBETADCIU && CoolUtil.difficulties[0] == "Guest")		
			suf = 'Guest';
		if (PlayState.isBETADCIU)		
			suf = 'BETADCIU';
		if (postfix != null) suf += '-' + postfix;
	
		return 'songs:assets/songs/${songLowercase}/'+pre+'Voices'+suf+'.$SOUND_EXT';
	}

	inline static public function inst(song:String)
	{
		var songLowercase = StringTools.replace(song, " ", "-").toLowerCase();
			switch (songLowercase) {
				case 'dad-battle': songLowercase = 'dadbattle';
				case 'philly-nice': songLowercase = 'philly';
			}

		var pre:String = "";
		var suf:String = "";

		if (Main.noCopyright && song.toLowerCase() == "sharkventure")
			pre = 'Alt_';		
		if (PlayState.isNeonight)
			suf = 'NN';
		if (PlayState.isVitor)		
			suf = 'V';
		if (PlayState.isBETADCIU && CoolUtil.difficulties[0] == "Guest" && Assets.exists('songs:assets/songs/${songLowercase}/'+'Inst'+'Guest'+'.$SOUND_EXT'))		
			suf = 'Guest';
	
		return 'songs:assets/songs/${songLowercase}/'+pre+'Inst'+suf+'.$SOUND_EXT';
	}

	inline static public function image(key:String, ?library:String)
	{
		#if MODS_ALLOWED
		if(FileSystem.exists(Paths.modsImages(key)))
			return Paths.modsImages(key);
		#end
			
		return getPath('images/$key.png', IMAGE, library);
	}

	inline static public function image2(key:String, ?library:String)
	{
		return getPath('images/$key', IMAGE, library);
	}

	inline static public function jsonNew(key:String, ?library:String)
	{
		if(FileSystem.exists(Paths.modFolders(key +'.json')))
			return Paths.modFolders(key +'.json');

		return getPath('$key.json', TEXT, library);
	}

	inline static public function font(key:String)
	{
		#if desktop
			var file:String = modsFont(key);
			if(FileSystem.exists(file)) {
				return file;
			}
		#end

		return 'assets/fonts/$key';
	}

	public static var currentTrackedAssets:Map<String, FlxGraphic> = [];
	public static var currentTrackedBitmaps:Map<String, BitmapData> = [];
	public static var currentTrackedSounds:Map<String, Sound> = [];
	public static var currentTrackedTextures:Map<String, Texture> = [];
	public static var currentTrackedTexts:Map<String, String> = [];
	public static var localTrackedAssets:Array<String> = [];

	//idk if this shit works. holy s%$t it did.
	public static function clearStoredMemory(?cleanUnused:Bool = false) {
		// clear anything not in the tracked assets list
		@:privateAccess
		for (key in FlxG.bitmap._cache.keys())
		{
			var obj = FlxG.bitmap._cache.get(key);
			if (obj != null && !currentTrackedAssets.exists(key))
			{
				openfl.Assets.cache.removeBitmapData(key);
				FlxG.bitmap._cache.remove(key);
				obj.destroy();
			}
		}

		// clear all sounds that are cached.
		for (key in currentTrackedSounds.keys()) {
			if (!localTrackedAssets.contains(key) 
			&& !dumpExclusions.contains(key) && key != null) {
				Assets.cache.clear(key);
				currentTrackedSounds.remove(key);
			}
		}

		// clear all texts
		for (key in currentTrackedTexts.keys()) {
			if (!localTrackedAssets.contains(key) 
			&& !dumpExclusions.contains(key) && key != null) {
				Assets.cache.clear(key);
				currentTrackedTexts.remove(key);
			}
		}
		
		// flags everything to be cleared out next unused memory clear
		localTrackedAssets = [];

		var pathsToCheck:Array<String> = ['songs', "shared:assets/shared/images/characters/jsons", "assets/images/characters/jsons", "mods", "assets/stages"];

		for (i in 0...pathsToCheck.length){
			openfl.Assets.cache.clear(pathsToCheck[i]);
		}

		trace ('cleared');
	}

	public static var dumpExclusions:Array<String> = [];

	/// haya I love you for the base cache dump I took to the max
	public static function clearUnusedMemory() {
		// clear non local assets in the tracked assets list
		for (key in currentTrackedAssets.keys()) {
			// if it is not currently contained within the used local assets
			if (!localTrackedAssets.contains(key) 
				&& !dumpExclusions.contains(key)) {
				// get rid of it
				if (currentTrackedTextures.exists(key)) {
					var texture:Null<Texture> = currentTrackedTextures.get(key);
					texture.dispose();
					texture = null;
					currentTrackedTextures.remove(key);
				}

				var obj = currentTrackedAssets.get(key);
				@:privateAccess
				if (obj != null) {
					openfl.Assets.cache.removeBitmapData(key);
					FlxG.bitmap._cache.remove(key);
					obj.destroy();
					currentTrackedAssets.remove(key);
				}
			}
		}
		// run the garbage collector for good measure lmfao
		System.gc();
	}


	// for uncaching midsong?
	public static function clearStoredMemory2(key:String, ?type:String = 'image') {
		// clear anything not in the tracked assets list
		trace ('uncaching ' + key);

		if (type == 'sound')
		{
			openfl.Assets.cache.clear(key);

			if(currentTrackedSounds.exists(key)) 
			{
				currentTrackedSounds.remove(key);
				trace('removed ' + key);
			}
		}
		else
		{
			@:privateAccess
			var obj = FlxG.bitmap._cache.get(key);
		
			if (currentTrackedTextures.exists(key)) {
				var texture:Null<Texture> = currentTrackedTextures.get(key);
				texture.dispose();
				texture = null;
				currentTrackedTextures.remove(key);
			}
			
			if (obj != null)
			{
				openfl.Assets.cache.removeBitmapData(key);
				@:privateAccess
				FlxG.bitmap._cache.remove(key);
				obj.destroy();
	
				if(currentTrackedAssets.exists(key)) 
					currentTrackedAssets.remove(key);

				trace ('success!');
			}
		}
		
		System.gc();
		trace ('check memory boi');
	}

	inline static public function formatToSongPath(path:String) {
		return path.toLowerCase().replace(' ', '-');
	}

	public static var globalMods:Array<String> = [];

	static public function getGlobalMods()
		return globalMods;

	static public function pushGlobalMods() // prob a better way to do this but idc
	{
		globalMods = [];
		var path:String = 'modsList.txt';
		if(FileSystem.exists(path))
		{
			var list:Array<String> = CoolUtil.coolTextFile(path);
			for (i in list)
			{
				var dat = i.split("|");
				if (dat[1] == "1")
				{
					var folder = dat[0];
					var path = Paths.mods(folder + '/pack.json');
					if(FileSystem.exists(path)) {
						try{
							var rawJson:String = File.getContent(path);
							if(rawJson != null && rawJson.length > 0) {
								var stuff:Dynamic = Json.parse(rawJson);
								var global:Bool = Reflect.getProperty(stuff, "runsGlobally");
								if(global)globalMods.push(dat[0]);
							}
						} catch(e:Dynamic){
							trace(e);
						}
					}
				}
			}
		}
		return globalMods;
	}
	
	public static function returnSound(path:String, key:String, ?library:String) {
		#if desktop
		var file:String = modsSounds(path, key);
		if(FileSystem.exists(file)) {
			if(!currentTrackedSounds.exists(file)) {
				currentTrackedSounds.set(file, Sound.fromFile(file));
			}
			//localTrackedAssets.push(key);
			return currentTrackedSounds.get(file);
		}
		#end
		// I hate this so god damn much
		var gottenPath:String = getPath('$path/$key.$SOUND_EXT', SOUND, library);	
		gottenPath = gottenPath.substring(gottenPath.indexOf(':') + 1, gottenPath.length);
		// trace(gottenPath);
		if(!currentTrackedSounds.exists(gottenPath)) 
		#if desktop
			currentTrackedSounds.set(gottenPath, Sound.fromFile('./' + gottenPath));
		#else
			currentTrackedSounds.set(gottenPath, OpenFlAssets.getSound(getPath('$path/$key.$SOUND_EXT', SOUND, library)));
		#end
		//localTrackedAssets.push(key);
		return currentTrackedSounds.get(gottenPath);
	}

	public static function imageExists(key:String, ?library:String = null)
	{
		var path:String = "ksajdlahfjhadjfhdshfkjhd";

		var pathsToCheck:Array<String> = [Paths.image(key), FileSystem.absolutePath("assets/shared/images/"+key+".png")];

		if (library != null)
			pathsToCheck.push(FileSystem.absolutePath("assets/"+library+"/images/"+key+".png"));

		for (i in 0...pathsToCheck.length)
		{
			if(FileSystem.exists(pathsToCheck[i]) || Assets.exists(pathsToCheck[i])) {
				return true;
			}
		}

		//trace('returning false for ' + (key));
		return false;
	}

	public static function imageExists2(key:String, ?library:String) {
		#if MODS_ALLOWED
		var modKey:String = modsImages(key);
		if(FileSystem.exists(modKey)) {
			return true;
		}
		#end

		var path = getPath('images/$key.png', IMAGE, library);
		if (OpenFlAssets.exists(path, IMAGE)) {
			return true;
		}
		return false;
	}

	public static function cacheImage(key:String, ?library:String = null, ?forced:Bool = false, ?antialiasing:Bool = true, ?preloadedBitmap:BitmapData = null)
	{
		var path:String = "";
	
		if (preloadedBitmap == null) {
			var pathsToCheck:Array<String> = [
				FileSystem.absolutePath("assets/shared/images/"+key+".png"), 
				Paths.image(key)
			];
	
			if (library != null)
				pathsToCheck.push(FileSystem.absolutePath("assets/"+library+"/images/"+key+".png"));
	
			#if MODS_ALLOWED
				pathsToCheck.push(modsImages(key));
			#end
	
			for (i in 0...pathsToCheck.length) {
				if (FileSystem.exists(pathsToCheck[i]) || Assets.exists(pathsToCheck[i])) {
					path = pathsToCheck[i];
					break;
				}
			}
		}
	
		if (preloadedBitmap != null || FileSystem.exists(path) || Assets.exists(path)) 
		{    
			if (!currentTrackedAssets.exists(key) || forced) 
			{
				var newBitmap:BitmapData = preloadedBitmap;
	
				if (newBitmap == null) {
					newBitmap = (FileSystem.exists(path) ? BitmapData.fromFile(path) : OpenFlAssets.getBitmapData(path));
				}
	
	
				if (ClientPrefs.data.useGL && newBitmap.image != null) {
					newBitmap.lock();
					if (newBitmap.__texture == null) {
						newBitmap.image.premultiplied = true;
						newBitmap.getTexture(FlxG.stage.context3D);
					}
					newBitmap.getSurface();
					newBitmap.disposeImage();
					newBitmap.image.data = null;
					newBitmap.image = null;
					newBitmap.readable = true;
				}
	
				var newGraphic:FlxGraphic = FlxGraphic.fromBitmapData(newBitmap, false, key);
				newGraphic.persist = true;
				currentTrackedAssets.set(key, newGraphic);

				if (ClientPrefs.data.multicoreLoading){
					currentTrackedBitmaps.set(key, newBitmap);
				}
			}
			localTrackedAssets.push(key);
			return currentTrackedAssets.get(key);
		}
	
		trace('cacheImage: You failed dipshit! Key '+key+" not found!");
		return null;        
	}

	static public function createGraphicsFromBitmaps() {
		for (key in currentTrackedBitmaps.keys()) {
			var bitmap = currentTrackedBitmaps.get(key);
			if (bitmap != null) {
				var newGraphic:FlxGraphic = FlxGraphic.fromBitmapData(bitmap, false, key); 
				newGraphic.persist = true;
				currentTrackedAssets.set(key, newGraphic);

				currentTrackedBitmaps.remove(key);
			}
		}
	}
	

	static public function getTextFromFile(key:String, ?ignoreMods:Bool = false):String
	{
		#if sys
		var path:String = "ksajdlahfjhadjfhdshfkjhd";

		var pathsToCheck:Array<String> = [FileSystem.absolutePath("assets/shared/"+key), Paths.getPreloadPath(key)];

		#if MODS_ALLOWED
			pathsToCheck.push(modFolders(key));
		#end

		for (i in 0...pathsToCheck.length)
		{
			if(FileSystem.exists(pathsToCheck[i]) || Assets.exists(pathsToCheck[i])) {
				path = pathsToCheck[i];
			}
		}
		
		if (FileSystem.exists(path) || Assets.exists(path)) 
		{	
			if (!currentTrackedTexts.exists(key))
			{
				var newText:String = (FileSystem.exists(path) ? File.getContent(path) : Assets.getText(path));		
				currentTrackedTexts.set(key, newText);
			}
			return currentTrackedTexts.get(key);
		}
		#end
		
		trace('getTextFromFile: You failed dipshit! Key '+key+" not found!");
		return null;		
	}

	public static var poltatoAlphabetXml:String = null;

	inline static public function getSparrowAtlas(key:String, ?library:String)
	{
		#if MODS_ALLOWED
		var imageLoaded:FlxGraphic = returnGraphic(key, library);
		var rawXml:String = "";

		rawXml = checkAndReturn("xml", key, library);
		
		if (imageLoaded == null){
			if (PlayState.instance != null && PlayState.inPlayState){
				PlayState.instance.addTextToDebug(key + " not found!");
			}
				
			imageLoaded = returnGraphic('bruhtf', 'shared');
		}
			
		if (rawXml == "")
			rawXml = Assets.getText(Paths.xmlNew('images/bruhtf')); //load something

		if (FlxG.save.data.poltatoPC && imageLoaded.width != 1)
		{
			if (key == 'alphabet' && poltatoAlphabetXml != null) //decrease the alphabet load time
				rawXml = poltatoAlphabetXml;
			else
			{
				rawXml = CoolUtil.resizeXML(rawXml, 0.5);
				
				if (key == 'alphabet')
					poltatoAlphabetXml = rawXml;
			}
		}
			
		return FlxAtlasFrames.fromSparrow(imageLoaded, rawXml);
		#else
		return FlxAtlasFrames.fromSparrow(image(key, library), file('images/$key.xml', library));
		#end
	}

	inline static public function getPackerAtlas(key:String, ?library:String)
	{
		#if MODS_ALLOWED
		var imageLoaded:FlxGraphic = returnGraphic(key, library);
		var rawTxt:String = "";

		rawTxt = checkAndReturn("txt", key, library);

		if (imageLoaded == null){
			if (PlayState.instance != null && PlayState.inPlayState){
				PlayState.instance.addTextToDebug(key + " not found!");
			}
			
			imageLoaded = returnGraphic('bruhtf', 'shared');
		}

		if (rawTxt == "")
			rawTxt = Assets.getText(Paths.txtNew('images/bruhtf')); //load something

		if (FlxG.save.data.poltatoPC)
			rawTxt = CoolUtil.resizeTxt(rawTxt, 0.5);

		return FlxAtlasFrames.fromSpriteSheetPacker(imageLoaded, rawTxt);
		#else
		return FlxAtlasFrames.fromSpriteSheetPacker(image(key, library), file('images/$key.txt', library));
		#end
	}

	inline static public function getXMLAtlas(key:String, ?library:String) //idk what to call this one
	{	#if MODS_ALLOWED
		var imageLoaded:FlxGraphic = returnGraphic(key, library);
		var rawXml:String = "";

		rawXml = checkAndReturn("xml", key, library);
		
		if (imageLoaded == null){
			if (PlayState.instance != null && PlayState.inPlayState){
				PlayState.instance.addTextToDebug(key + " not found!");
			}
			
			imageLoaded = returnGraphic('bruhtf', 'shared');
		}

		if (rawXml == "")
			rawXml = Assets.getText(Paths.xmlNew('images/bruhtfgeneric')); //load something

		return FlxAtlasFrames.fromTexturePackerXml(imageLoaded, rawXml);
		#else
		return FlxAtlasFrames.fromTexturePackerXml(image(key, library), file('images/$key.xml', library));
		#end
	}

	inline static public function getJSONAtlas(key:String, ?library:String)
	{
		#if MODS_ALLOWED
		var imageLoaded:FlxGraphic = returnGraphic(key, library);
		var rawJson:String = "";

		rawJson = checkAndReturn("json", key, "library");
		
		if (imageLoaded == null){
			if (PlayState.instance != null && PlayState.inPlayState){
				PlayState.instance.addTextToDebug(key + " not found!");
			}
			
			imageLoaded = returnGraphic('bruhtf', 'shared');
		}

		if (rawJson == "")
			rawJson = Assets.getText(Paths.jsonNew('images/bruhtf')); //load something

		return FlxAtlasFrames.fromTexturePackerJson(imageLoaded, rawJson);
		#else
		return FlxAtlasFrames.fromTexturePackerJson(image(key, library), file('images/$key.json', library));
		#end
	}

	inline static public function fileExists(key:String, type:AssetType, ?ignoreMods:Bool = false, ?library:String)
	{		
		#if desktop
		if(FileSystem.exists(mods(Mods.currentModDirectory + '/' + key)) || FileSystem.exists(mods(key))) {
			return true;
		}
		#end
		
		if(OpenFlAssets.exists(Paths.getPath(key, type))) {
			return true;
		}
		return false;
	}

	//return graphic didn't work for me so...
	inline static public function existsInCTA(key:String)
	{
		var daThing:Dynamic;

		if (!Paths.currentTrackedAssets.exists(key))
			Paths.cacheImage(key);

		daThing = Paths.currentTrackedAssets.get(key);

		return daThing;
	}

	inline static public function fileExists2(key:String)
	{
		return (Assets.exists(key) || FileSystem.exists(key));
	}

	static public function getAtlasFromData(key:String, data:String = "SPARROW")
	{
		switch (data.toLowerCase())
		{
			case 'sparrow':
				return getSparrowAtlas(key);
			case 'genericxml':
				return getXMLAtlas(key);
			case 'packer':
				return getPackerAtlas(key);
			case 'json':
				return getJSONAtlas(key);
		}

		return getSparrowAtlas(key);
	}

	static function checkAndReturn(fileType:String = "xml", key:String, ?library:String = null)
	{
		var pathsToCheck:Array<String> = [];

		switch (fileType.toLowerCase())
		{
			case "xml":
				pathsToCheck = [modsXml(key), FileSystem.absolutePath("assets/shared/images/"+key+".xml"), Paths.xmlNew('images/' + key)];
			case "txt":
				pathsToCheck = [modsTxt(key), FileSystem.absolutePath("assets/shared/images/"+key+".txt"), Paths.txtNew('images/' + key)];
			case "json":
				pathsToCheck = [modsJson(key), FileSystem.absolutePath("assets/shared/images/"+key+".json"), Paths.jsonNew('images/' + key)];
		}

		if (library != null)
			pathsToCheck.push(FileSystem.absolutePath("assets/"+library+"/images/"+key+"."+fileType.toLowerCase()));
		
		for (i in 0...pathsToCheck.length)
		{
			//prioritize stuff in the mods folder first.
			if(FileSystem.exists(pathsToCheck[i])) {
				return File.getContent(pathsToCheck[i]);
			}

			if(Assets.exists(pathsToCheck[i])) {
				return Assets.getText(pathsToCheck[i]);
			}
		}

		return "";
	}

	#if desktop
	inline static public function mods(key:String = '') {
		return 'mods/' + key;
	}
	
	inline static public function modsFont(key:String) {
		return modFolders('fonts/' + key);
	}

	inline static public function modsJson(key:String) {
		return modFolders('data/' + key + '.json');
	}

	inline static public function modsVideo(key:String) {
		return modFolders('videos/' + key + '.mp4');
	}

	inline static public function modsSounds(path:String, key:String) {
		return modFolders(path + '/' + key + '.' + SOUND_EXT);
	}

	inline static public function modsImages(key:String) {
		return modFolders('images/' + key + '.png');
	}

	inline static public function modsXml(key:String) {
		return modFolders('images/' + key + '.xml');
	}

	inline static public function modsTxt(key:String) {
		return modFolders('images/' + key + '.txt');
	}

	inline static public function modsAchievements(key:String) {
		return modFolders('achievements/' + key + '.json');
	}

	static public function modFolders(key:String) {
		if(Mods.currentModDirectory != null && Mods.currentModDirectory.length > 0) {
			var fileToCheck:String = mods(Mods.currentModDirectory + '/' + key);
			if(FileSystem.exists(fileToCheck)) {
				return fileToCheck;
			}
		}

		for(mod in getGlobalMods()){
			var fileToCheck:String = mods(mod + '/' + key);
			if(FileSystem.exists(fileToCheck))
				return fileToCheck;

		}

		return 'mods/' + key;
	}

	static public function getModDirectories():Array<String> {
		var list:Array<String> = [];
		var modsFolder:String = Paths.mods();
		if(FileSystem.exists(modsFolder)) {
			for (folder in FileSystem.readDirectory(modsFolder)) {
				var path = haxe.io.Path.join([modsFolder, folder]);
				if (sys.FileSystem.isDirectory(path) && !Paths.ignoreModFolders.contains(folder) && !list.contains(folder)) {
					list.push(folder);
				}
			}
		}
		return list;
	}
	#end

	#if flxanimate
	public static function loadAnimateAtlas(spr:FlxAnimate, folderOrImg:Dynamic, spriteJson:Dynamic = null, animationJson:Dynamic = null)
	{
		var changedAnimJson = false;
		var changedAtlasJson = false;
		var changedImage = false;
		
		if(spriteJson != null)
		{
			changedAtlasJson = true;
			spriteJson = File.getContent(spriteJson);
		}

		if(animationJson != null) 
		{
			changedAnimJson = true;
			animationJson = File.getContent(animationJson);
		}

		// is folder or image path
		if(Std.isOfType(folderOrImg, String))
		{
			var originalPath:String = folderOrImg;
			for (i in 0...10)
			{
				var st:String = '$i';
				if(i == 0) st = '';

				if(!changedAtlasJson)
				{
					spriteJson = getTextFromFile('images/$originalPath/spritemap$st.json');
					if(spriteJson != null)
					{
						trace('found Sprite Json');
						changedImage = true;
						changedAtlasJson = true;
						folderOrImg = returnGraphic('$originalPath/spritemap$st');
						break;
					}
				}
				else if(fileExists('images/$originalPath/spritemap$st.png', IMAGE))
				{
					trace('found Sprite PNG');
					changedImage = true;
					folderOrImg = returnGraphic('$originalPath/spritemap$st');
					break;
				}
			}

			if(!changedImage)
			{
				trace('Changing folderOrImg to FlxGraphic');
				changedImage = true;
				folderOrImg = returnGraphic(originalPath);
			}

			if(!changedAnimJson)
			{
				trace('found Animation Json');
				changedAnimJson = true;
				animationJson = getTextFromFile('images/$originalPath/Animation.json');
			}
		}
		
		trace(folderOrImg);
		//trace(spriteJson);
		//trace(animationJson);

		spr.loadAtlasEx(folderOrImg, spriteJson, animationJson);
	}
	#end
}