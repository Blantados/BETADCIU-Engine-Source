package backend;

import flixel.graphics.frames.FlxFrame.FlxFrameAngle;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.FlxGraphic;
import flixel.math.FlxRect;
import flixel.system.FlxAssets;

import openfl.display.BitmapData;
import openfl.display3D.textures.RectangleTexture;
import openfl.utils.AssetType;
import openfl.utils.Assets as OpenFlAssets;
import openfl.system.System;
import openfl.geom.Rectangle;
import animate.FlxAnimateFrames;

import lime.utils.Assets;
import flash.media.Sound;

import haxe.Json;
import backend.system.OptimizedBitmapData;

#if MODS_ALLOWED
import backend.Mods;
#end

@:access(openfl.display.BitmapData)
class Paths
{
	inline public static var SOUND_EXT = "ogg";
	inline public static var VIDEO_EXT = "mp4";

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

	private static var _previousErrorMessage:String = ""; // No more spammed errors

	public static function excludeAsset(key:String) {
		if (!dumpExclusions.contains(key))
			dumpExclusions.push(key);
	}

	public static var dumpExclusions:Array<String> = ['assets/shared/music/freakyMenu.$SOUND_EXT'];
	// haya I love you for the base cache dump I took to the max
	public static function clearUnusedMemory()
	{
		for (key in currentTrackedFrames.keys()){
			currentTrackedFrames.remove(key); // and remove the key from local cache map
		}

		// clear non local assets in the tracked assets list
		for (key in currentTrackedAssets.keys())
		{
			// if it is not currently contained within the used local assets
			if (!localTrackedAssets.contains(key) && !dumpExclusions.contains(key))
			{
				destroyGraphic(currentTrackedAssets.get(key)); // get rid of the graphic
				currentTrackedAssets.remove(key); // and remove the key from local cache map
			}
		}

		// run the garbage collector for good measure lmfao
		System.gc();
	}

	// define the locally tracked assets
	public static var localTrackedAssets:Array<String> = [];

	@:access(flixel.system.frontEnds.BitmapFrontEnd._cache)
	public static function clearStoredMemory()
	{
		// clear anything not in the tracked assets list
		for (key in FlxG.bitmap._cache.keys())
		{
			if (!currentTrackedAssets.exists(key))
				destroyGraphic(FlxG.bitmap.get(key));
		}

		// clear all sounds that are cached
		for (key => asset in currentTrackedSounds)
		{
			if (!localTrackedAssets.contains(key) && !dumpExclusions.contains(key) && asset != null)
			{
				Assets.cache.clear(key);
				currentTrackedSounds.remove(key);
			}
		}

		// Hope this works...
		for(key => asset in currentTrackedTexts){
			if (!localTrackedAssets.contains(key) && !dumpExclusions.contains(key) && asset != null)
			{
				currentTrackedTexts.remove(key);
			}
		}

		openfl.Assets.cache.clear("fonts");

		// flags everything to be cleared out next unused memory clear
		localTrackedAssets = [];
		openfl.Assets.cache.clear("songs");
	}

	// for softcode uncaching
	@:access(flixel.system.frontEnds.BitmapFrontEnd._cache)
	public static function clearAssetFromMemory(key:String, ?type:String = 'image') {
		// clear anything not in the tracked assets list
		trace ('uncaching ' + key);

		switch (type){
			case "sound":
				openfl.Assets.cache.clear(key);

				if(currentTrackedSounds.exists(key)) {
					currentTrackedSounds.remove(key);
					trace('uncached sound: $key');
				}
			case "text":
				openfl.Assets.cache.clear(key);
				if (currentTrackedTexts.exists(key)){
					currentTrackedTexts.remove(key);
				}
				trace('uncached text: $key');
			default:
				@:privateAccess
				var obj = FlxG.bitmap._cache.get(key);
				if (obj != null) {
					openfl.Assets.cache.removeBitmapData(key);
					@:privateAccess
					FlxG.bitmap._cache.remove(key);
					obj.destroy();

					if(currentTrackedAssets.exists(key)) currentTrackedAssets.remove(key);
					
					trace ('uncached image: $key');
				}
		}
		
		System.gc();
		trace ('check memory boi');
	}

	public static function freeGraphicsFromMemory()
	{
		var protectedGfx:Array<FlxGraphic> = [];
		function checkForGraphics(spr:Dynamic)
		{
			try
			{
				var grp:Array<Dynamic> = Reflect.getProperty(spr, 'members');
				if(grp != null)
				{
					//trace('is actually a group');
					for (member in grp)
					{
						checkForGraphics(member);
					}
					return;
				}
			}

			//trace('check...');
			try
			{
				var gfx:FlxGraphic = Reflect.getProperty(spr, 'graphic');
				if(gfx != null)
				{
					protectedGfx.push(gfx);
					//trace('gfx added to the list successfully!');
				}
			}
			//catch(haxe.Exception) {}
		}

		for (member in FlxG.state.members)
			checkForGraphics(member);

		if(FlxG.state.subState != null)
			for (member in FlxG.state.subState.members)
				checkForGraphics(member);

		for (key in currentTrackedAssets.keys())
		{
			// if it is not currently contained within the used local assets
			if (!dumpExclusions.contains(key))
			{
				var graphic:FlxGraphic = currentTrackedAssets.get(key);
				if(!protectedGfx.contains(graphic))
				{
					destroyGraphic(graphic); // get rid of the graphic
					currentTrackedAssets.remove(key); // and remove the key from local cache map
					//trace('deleted $key');
				}
			}
		}
	}

	inline static function destroyGraphic(graphic:FlxGraphic)
	{
		// free some gpu memory
		if (graphic != null && graphic.bitmap != null && graphic.bitmap.__texture != null)
			graphic.bitmap.__texture.dispose();
		FlxG.bitmap.remove(graphic);
	}

	static public var currentLevel:String;
	static public function setCurrentLevel(name:String)
		currentLevel = name.toLowerCase();

	public static function getPath(file:String, ?type:AssetType = TEXT, ?parentfolder:String, ?modsAllowed:Bool = true):String
	{
		#if MODS_ALLOWED
		if(modsAllowed)
		{
			var customFile:String = file;
			if (parentfolder != null) customFile = '$parentfolder/$file';

			var modded:String = modFolders(customFile);
			if(FileSystem.exists(modded)) return modded;
		}
		#end

		if (parentfolder != null)
			return getFolderPath(file, parentfolder);

		if (currentLevel != null && currentLevel != 'shared')
		{
			var levelPath = getFolderPath(file, currentLevel);
			if (OpenFlAssets.exists(levelPath, type))
				return levelPath;
		}

        var sharedPath:String = getSharedPath(file);
        if (OpenFlAssets.exists(sharedPath, type)) return sharedPath;

        var preloadPath:String = getPreloadPath(file);
        if (OpenFlAssets.exists(preloadPath, type)) return preloadPath;

		return getSharedPath(file); // idk if returning the getPreloadPath as a default thing would conflict with anything, so i'll keep returning this
	}

	inline public static function getPreloadPath(file:String = "")
	{
		return 'assets/$file';
	}

	inline static public function getFolderPath(file:String, folder = "shared")
		return 'assets/$folder/$file';

	inline public static function getSharedPath(file:String = '')
		return 'assets/shared/$file';

	inline static public function txt(key:String, ?folder:String)
		return getPath('data/$key.txt', TEXT, folder, true);

	inline static public function xml(key:String, ?folder:String)
		return getPath('data/$key.xml', TEXT, folder, true);

	inline static public function json(key:String, ?folder:String)
		return getPath('data/$key.json', TEXT, folder, true);

	inline static public function shaderFragment(key:String, ?folder:String)
		return getPath('shaders/$key.frag', TEXT, folder, true);

	inline static public function shaderVertex(key:String, ?folder:String)
		return getPath('shaders/$key.vert', TEXT, folder, true);

	inline static public function lua(key:String, ?folder:String)
		return getPath('$key.lua', TEXT, folder, true);

	inline static public function file(file:String, type:AssetType = TEXT, ?library:String)
		return getPath(file, type, library);

	static public function video(key:String)
	{
		#if MODS_ALLOWED
		var file:String = modsVideo(key);
		if(FileSystem.exists(file)) return file;
		#end
		return 'assets/videos/$key.$VIDEO_EXT';
	}

	inline static public function sound(key:String, ?modsAllowed:Bool = true):Sound
		return returnSound('sounds/$key', modsAllowed);

	inline static public function song(key:String, ?modsAllowed:Bool = true):Sound
		return returnSound('songs/$key', modsAllowed);

	inline static public function music(key:String, ?modsAllowed:Bool = true):Sound
		return returnSound('music/$key', modsAllowed);

	inline static public function inst(song:String, ?modsAllowed:Bool = true):Sound
		return returnSound('${formatToSongPath(song)}/Inst', 'songs', modsAllowed);

	inline static public function voices(song:String, postfix:String = null, ?modsAllowed:Bool = true):Sound
	{
		var songKey:String = '${formatToSongPath(song)}/Voices';
		if(postfix != null) songKey += '-' + postfix;
		//trace('songKey test: $songKey');
		return returnSound(songKey, 'songs', modsAllowed, false);
	}

	inline static public function soundRandom(key:String, min:Int, max:Int, ?modsAllowed:Bool = true)
		return sound(key + FlxG.random.int(min, max), modsAllowed);

	public static var currentTrackedAssets:Map<String, FlxGraphic> = [];
	public static var currentTrackedFrames:Map<String, FlxAtlasFrames> = [];
	
	static public function image(key:String, ?parentFolder:String = null, ?allowGPU:Bool = true, ?folder:String="images/"):FlxGraphic
	{
		key = Language.getFileTranslation(folder + key) + '.png';
		var bitmap:BitmapData = null;
		if (currentTrackedAssets.exists(key))
		{
			localTrackedAssets.push(key);
			return currentTrackedAssets.get(key);
		}

		return cacheBitmap(key, parentFolder, bitmap, allowGPU);
	}

	public static function cacheBitmap(key:String, ?parentFolder:String = null, ?bitmap:BitmapData, ?allowGPU:Bool = true):FlxGraphic
	{
		final useGPU:Bool = allowGPU && ClientPrefs.data.cacheOnGPU;

		if (bitmap == null)
		{
			final file:String = getPath(key, IMAGE, parentFolder, true);

			#if MODS_ALLOWED
			if (FileSystem.exists(file)) {
				bitmap = useGPU ? OptimizedBitmapData.fromFile(file) : BitmapData.fromFile(file);
			} else
			#end
			if (OpenFlAssets.exists(file, IMAGE)) {
				bitmap = useGPU ? OptimizedBitmapData.fromAsset(file) : OpenFlAssets.getBitmapData(file);
			}

			if (bitmap == null) {
				var errorMessage:String = 'Bitmap not found: $file | key: $key';
				if (errorMessage != _previousErrorMessage)
				{
					trace(errorMessage);
					_previousErrorMessage = errorMessage;
				}
				return null;
			}
		}
		var graph:FlxGraphic = FlxGraphic.fromBitmapData(bitmap, false, key);
		graph.persist = true;
		graph.destroyOnNoUse = false;

		currentTrackedAssets.set(key, graph);
		localTrackedAssets.push(key);
		return graph;
	}

	public static var currentTrackedTexts:Map<String, String> = [];
	inline static public function getTextFromFile(key:String, ?ignoreMods:Bool = false):String
	{
		if (currentTrackedTexts.exists(key)) {
            return currentTrackedTexts.get(key);
        }

        var path:String = getPath(key, TEXT, !ignoreMods);
        var text:String;

        #if sys
		text = (FileSystem.exists(path)) ? File.getContent(path) : null;
        #else
		text = (OpenFlAssets.exists(path, TEXT)) ? Assets.getText(path) : null;
        #end

        if (text != null) {
            currentTrackedTexts.set(key, text);
        }

        return text;
	}

	inline static public function font(key:String)
	{
		var folderKey:String = Language.getFileTranslation('fonts/$key');
		#if MODS_ALLOWED
		var file:String = modFolders(folderKey);
		if(FileSystem.exists(file)) return file;
		#end
		return 'assets/$folderKey';
	}

	public static function fileExists(key:String, type:AssetType, ?ignoreMods:Bool = false, ?parentFolder:String = null)
	{
		#if MODS_ALLOWED
		if(!ignoreMods)
		{
			var modKey:String = key;
			if(parentFolder == 'songs') modKey = 'songs/$key';

			for(mod in Mods.getGlobalMods())
				if (FileSystem.exists(mods('$mod/$modKey')))
					return true;

			if (FileSystem.exists(mods(Mods.currentModDirectory + '/' + modKey)) || FileSystem.exists(mods(modKey)))
				return true;
		}
		#end
		return (OpenFlAssets.exists(getPath(key, type, parentFolder, false)));
	}

	public static function getContent(path:String):String
	{
		#if (MODS_ALLOWED || ASSET_REDIRECT)
		if (FileSystem.exists(path)) return File.getContent(path);
		else
		#end
		if (Assets.exists(path)) return Assets.getText(path);
		else
		{
			throw 'Couldnt find file at path [$path]';
		}
	}

	public static function exists(path:String, ?type:AssetType):Bool
	{
		var exists:Bool = false;
		
		#if (MODS_ALLOWED || ASSET_REDIRECT)
		if(FileSystem.exists(path)) exists = true;
		else {
			path = Paths.getSharedPath(path);
			if(FileSystem.exists(path)) exists = true;
		}
		#end
		if (Assets.exists(path, cast type)) exists = true;
		
		return exists;
	}

	public static inline function fragment(key:String, checkMods:Bool = true):String
	{
		return getPath('shaders/$key.frag', null, checkMods);
	}
	
	public static inline function vertex(key:String, checkMods:Bool = true):String
	{
		return getPath('shaders/$key.vert', null, checkMods);
	}

	static public function getAtlas(key:String, ?parentFolder:String = null, ?allowGPU:Bool = true, ?folder:String="images/"):FlxAtlasFrames
	{
		var useMod = false;
		var imageLoaded:FlxGraphic = image(key, parentFolder, allowGPU, folder);

		var myXml:Dynamic = getPath(folder + '$key.xml', TEXT, parentFolder, true);
		if(OpenFlAssets.exists(myXml) #if MODS_ALLOWED || (FileSystem.exists(myXml) && (useMod = true)) #end )
		{
			#if MODS_ALLOWED
			return FlxAtlasFrames.fromSparrow(imageLoaded, (useMod ? File.getContent(myXml) : myXml));
			#else
			return FlxAtlasFrames.fromSparrow(imageLoaded, myXml);
			#end
		}
		else
		{
			var myJson:Dynamic = getPath(folder + '$key.json', TEXT, parentFolder, true);
			if(OpenFlAssets.exists(myJson) #if MODS_ALLOWED || (FileSystem.exists(myJson) && (useMod = true)) #end )
			{
				#if MODS_ALLOWED
				return FlxAtlasFrames.fromTexturePackerJson(imageLoaded, (useMod ? File.getContent(myJson) : myJson));
				#else
				return FlxAtlasFrames.fromTexturePackerJson(imageLoaded, myJson);
				#end
			}
		}
		return getPackerAtlas(key, parentFolder);
	}
	
	static public function getMultiAtlas(keys:Array<String>, ?parentFolder:String = null, ?allowGPU:Bool = true):FlxAtlasFrames
	{
		var parentFrames:FlxAtlasFrames = Paths.getAtlas(keys[0].trim());
		if(keys.length > 1)
		{
			var original:FlxAtlasFrames = parentFrames;
			parentFrames = new FlxAtlasFrames(parentFrames.parent);
			parentFrames.addAtlas(original, true);
			for (i in 1...keys.length)
			{
				var extraFrames:FlxAtlasFrames = Paths.getAtlas(keys[i].trim(), parentFolder, allowGPU);
				if(extraFrames != null)
					parentFrames.addAtlas(extraFrames, true);
			}
		}
		
		return parentFrames;
	}

	inline static public function getSparrowAtlas(key:String, ?parentFolder:String = null, ?allowGPU:Bool = true, ?folder:String="images/"):FlxAtlasFrames
	{
		if(key.contains('psychic')) trace(key, parentFolder, allowGPU);
		var imageLoaded:FlxGraphic = image(key, parentFolder, allowGPU, folder);
		#if MODS_ALLOWED
		var xmlExists:Bool = false;

		var xml:String = modsXml(key);
		if(FileSystem.exists(xml)) xmlExists = true;

		return FlxAtlasFrames.fromSparrow(imageLoaded, (xmlExists ? File.getContent(xml) : getPath(Language.getFileTranslation(folder + key) + '.xml', TEXT, parentFolder)));
		#else
		return FlxAtlasFrames.fromSparrow(imageLoaded, getPath(Language.getFileTranslation(folder + key) + '.xml', TEXT, parentFolder));
		#end
	}

	inline static public function getPackerAtlas(key:String, ?parentFolder:String = null, ?allowGPU:Bool = true, ?folder:String="images/"):FlxAtlasFrames
	{
		var imageLoaded:FlxGraphic = image(key, parentFolder, allowGPU, folder);
		#if MODS_ALLOWED
		var txtExists:Bool = false;
		
		var txt:String = modsTxt(key);
		if(FileSystem.exists(txt)) txtExists = true;

		return FlxAtlasFrames.fromSpriteSheetPacker(imageLoaded, (txtExists ? File.getContent(txt) : getPath(Language.getFileTranslation(folder + key) + '.txt', TEXT, parentFolder)));
		#else
		return FlxAtlasFrames.fromSpriteSheetPacker(imageLoaded, getPath(Language.getFileTranslation(folder + key) + '.txt', TEXT, parentFolder));
		#end
	}

	inline static public function getAsepriteAtlas(key:String, ?parentFolder:String = null, ?allowGPU:Bool = true, ?folder:String="images/"):FlxAtlasFrames
	{
		var imageLoaded:FlxGraphic = image(key, parentFolder, allowGPU, folder);
		#if MODS_ALLOWED
		var jsonExists:Bool = false;

		var json:String = modsImagesJson(key);
		if(FileSystem.exists(json)) jsonExists = true;

		return FlxAtlasFrames.fromTexturePackerJson(imageLoaded, (jsonExists ? File.getContent(json) : getPath(Language.getFileTranslation(folder + key) + '.json', TEXT, parentFolder)));
		#else
		return FlxAtlasFrames.fromTexturePackerJson(imageLoaded, getPath(Language.getFileTranslation(folder + key) + '.json', TEXT, parentFolder));
		#end
	}

	public static function getAnimateAtlas(key:String, ?parentFolder:String, ?settings:FlxAnimateSettings, ?folder:String="images/"):FlxAnimateFrames // my attempt to make the preloading work automatically
	{
		var framesFound:Array<FlxAtlasFrames> = [];
		var graphicKey = getPath(folder + key, TEXT, parentFolder, true);
		if (!FileSystem.exists('${graphicKey}/Animation.json')) throw 'No Animation.json file exists at the specified path (${graphicKey})';

		var validatedSettings:FlxAnimateSettings = {
			swfMode: settings?.swfMode ?? false,
			cacheOnLoad: settings?.cacheOnLoad ?? true,
			filterQuality: settings?.filterQuality ?? MEDIUM,
			onSymbolCreate: settings?.onSymbolCreate ?? null,
		};

		// var t = haxe.Timer.stamp();
		var atlas = FlxAnimateFrames.fromAnimate(graphicKey, null, null, null, false, validatedSettings);
		if (atlas != null) {
			if (ClientPrefs.data.cacheOnGPU && atlas.parent.bitmap != null) atlas.parent.bitmap.disposeImage();
			framesFound.push(atlas);

			for (collection in framesFound) {
				@:privateAccess {
					var path = collection.parent.key;
				}

				collection.parent.persist = true; // trusting the internal flixel-animate cache for this :pray::pray:
				collection.parent.destroyOnNoUse = false; // trusting the internal flixel-animate cache for this :pray::pray:			
			}
		}
		// trace('fromAnimate "$key" took: ' + (haxe.Timer.stamp() - t) + 's');

		return atlas;
	}

	inline static public function formatToSongPath(path:String) {
		final invalidChars = ~/[~&;:<>#\s]/g;
		final hideChars = ~/[.,'"%?!]/g;

		return hideChars.replace(invalidChars.replace(path, '-'), '').trim().toLowerCase();
	}

	public static var currentTrackedSounds:Map<String, Sound> = [];
	public static function returnSound(key:String, ?path:String, ?modsAllowed:Bool = true, ?beepOnNull:Bool = true)
	{
		var file:String = getPath(Language.getFileTranslation(key) + '.$SOUND_EXT', SOUND, path, modsAllowed);

		//trace('precaching sound: $file');
		if(!currentTrackedSounds.exists(file))
		{
			#if sys
			if(FileSystem.exists(file))
				currentTrackedSounds.set(file, Sound.fromFile(file));
			#else
			if(OpenFlAssets.exists(file, SOUND))
				currentTrackedSounds.set(file, OpenFlAssets.getSound(file));
			#end
			else if(beepOnNull)
			{
				var errorMessage:String = 'SOUND NOT FOUND: $key, PATH: $path';
				if (errorMessage != _previousErrorMessage) {
					trace(errorMessage);
					FlxG.log.error(errorMessage);
					_previousErrorMessage = errorMessage;
				}
				return FlxAssets.getSound('flixel/sounds/beep');
			}
		}
		localTrackedAssets.push(file);
		return currentTrackedSounds.get(file);
	}

	#if MODS_ALLOWED
	inline static public function mods(key:String = '')
		return 'mods/' + key;

	inline static public function modsJson(key:String)
		return modFolders('data/' + key + '.json');

	inline static public function modsVideo(key:String)
		return modFolders('videos/' + key + '.' + VIDEO_EXT);

	inline static public function modsAnimateAtlas(key:String)
		return modFolders('images/' + key);

	inline static public function modsSounds(path:String, key:String)
		return modFolders(path + '/' + key + '.' + SOUND_EXT);

	inline static public function modsImages(key:String)
		return modFolders('images/' + key + '.png');

	inline static public function modsXml(key:String)
		return modFolders('images/' + key + '.xml');

	inline static public function modsTxt(key:String)
		return modFolders('images/' + key + '.txt');

	inline static public function modsImagesJson(key:String)
		return modFolders('images/' + key + '.json');

	static public function modFolders(key:String)
	{
		if(Mods.currentModDirectory != null && Mods.currentModDirectory.length > 0)
		{
			var fileToCheck:String = mods(Mods.currentModDirectory + '/' + key);
			if(FileSystem.exists(fileToCheck))
				return fileToCheck;
		}

		for(mod in Mods.getGlobalMods())
		{
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
}

enum abstract PathsFunction(String)
{
  public var MUSIC;
  public var INST;
  public var VOICES;
  public var SOUND;
}