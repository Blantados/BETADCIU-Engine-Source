package backend.system.sound;

import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.sound.FlxSound;
import flixel.system.FlxAssets.FlxSoundAsset;
import flixel.util.FlxSignal.FlxTypedSignal;
import backend.system.sound.waveform.*;
import backend.tools.ICloneable;
// import backend.system.sound.FlxPartialSound; // still have to implement this so imma comment this for now
import backend.Paths.PathsFunction;
import lime.app.Promise;
import lime.media.AudioSource;
import openfl.events.Event;
import openfl.media.SoundChannel;
import openfl.media.SoundMixer;

// a bit stripped down version of FunkinSound from base game

/**
 * A FlxSound which adds additional functionality:
 * - Delayed playback via negative song position.
 * - Easy functions for immediate playback and recycling.
 */
@:nullSafety
class FunkinSound extends FlxSound implements ICloneable<FunkinSound>
{
  static final MAX_VOLUME:Float = 1.0;

  /**
   * An FlxSignal which is dispatched when the volume changes.
   */
  public static var onVolumeChanged(get, never):FlxTypedSignal<Float->Void>;

  static var _onVolumeChanged:Null<FlxTypedSignal<Float->Void>> = null;

  static function get_onVolumeChanged():FlxTypedSignal<Float->Void>
  {
    if (_onVolumeChanged == null)
    {
      _onVolumeChanged = new FlxTypedSignal<Float->Void>();
      FlxG.sound.onVolumeChange.add(function(volume:Float)
      {
        _onVolumeChanged.dispatch(volume);
      });
    }
    return _onVolumeChanged;
  }

  /**
   * Using `FunkinSound.load` will override a dead instance from here rather than creating a new one, if possible!
   */
  static var pool(default, null):FlxTypedGroup<FunkinSound> = new FlxTypedGroup<FunkinSound>();

  /**
   * Calculate the current time of the sound.
   * NOTE: You need to `add()` the sound to the scene for `update()` to increment the time.
   */
  //
  public var muted(default, set):Bool = false;

  function set_muted(value:Bool):Bool
  {
    if (value == muted) return value;
    muted = value;
    updateTransform();
    return value;
  }

  override function set_volume(value:Float):Float
  {
    // Uncap the volume.
    // _volume = value.clamp(0.0, MAX_VOLUME);
    _volume = Math.max(0.0, Math.min(MAX_VOLUME, value));
    updateTransform();
    return _volume;
  }

  public var paused(get, never):Bool;

  function get_paused():Bool
  {
    return this._paused;
  }

  public var isPlaying(get, never):Bool;

  function get_isPlaying():Bool
  {
    return this.playing || this._shouldPlay;
  }

  /**
   * Waveform data for this sound.
   * This is lazily loaded, so it will be built the first time it is accessed.
   */
  public var waveformData(get, never):WaveformData;

  var _waveformData:Null<WaveformData> = null;

  function get_waveformData():WaveformData
  {
    if (_waveformData == null)
    {
      _waveformData = WaveformDataParser.interpretFlxSound(this);
      if (_waveformData == null) throw 'Could not interpret waveform data!';
    }
    return _waveformData;
  }

  /**
   * If true, the game will forcefully add this sound's channel to the list of playing sounds.
   */
  public var important:Bool = false;

  /**
   * Are we in a state where the song should play but time is negative?
   */
  var _shouldPlay:Bool = false;

  /**
   * For debug purposes.
   */
  var _label:String = 'unknown';

  public function new()
  {
    super();
  }

  override public function update(elapsedSec:Float)
  {
    if (!playing && !_shouldPlay) return;

    if (_time < 0)
    {
      var elapsedMs = elapsedSec * 1000;
      _time += elapsedMs;
      if (_time >= 0)
      {
        super.play();
        _shouldPlay = false;
      }
    }
    else
    {
      super.update(elapsedSec);

      @:privateAccess
      {
        if (important && _channel != null && !SoundMixer.__soundChannels.contains(_channel))
        {
          SoundMixer.__soundChannels.push(_channel);
        }
      }
    }
  }

  public function togglePlayback():FunkinSound
  {
    if (playing)
    {
      pause();
    }
    else
    {
      resume();
    }
    return this;
  }

  override public function play(forceRestart:Bool = false, startTime:Float = 0, ?endTime:Float):FunkinSound
  {
    if (!exists) return this;

    if (forceRestart)
    {
      cleanup(false, true);
    }
    else if (playing)
    {
      return this;
    }

    if (startTime < 0)
    {
      this.active = true;
      this._shouldPlay = true;
      this._time = startTime;
      this.endTime = endTime;
      return this;
    }
    else
    {
      if (_paused)
      {
        resume();
      }
      else
      {
        startSound(startTime);
      }

      this.endTime = endTime;
      return this;
    }
  }

  override public function pause():FunkinSound
  {
    if (_shouldPlay)
    {
      // This sound will eventually play, but is still at a negative timestamp.
      // Manually set the paused flag to ensure proper focus/unfocus behavior.
      _shouldPlay = false;
      _paused = true;
      active = false;
    }
    else
    {
      super.pause();
    }
    return this;
  }

  override public function resume():FunkinSound
  {
    if (this._time < 0)
    {
      // Sound with negative timestamp, restart the timer.
      _shouldPlay = true;
      _paused = false;
      active = true;
    }
    else
    {
      super.resume();
    }
    return this;
  }

  /**
   * Call after adjusting the volume to update the sound channel's settings.
   */
  @:allow(flixel.sound.FlxSoundGroup)
  override function updateTransform():Void
  {
    if (_transform != null)
    {
      _transform.volume = #if FLX_SOUND_SYSTEM ((FlxG.sound.muted || this.muted) ? 0 : 1) * FlxG.sound.volume * #end
        (group != null ? group.volume : 1) * _volume * _volumeAdjust;
    }

    if (_channel != null)
    {
      _channel.soundTransform = _transform;
    }
  }

  public function clone():FunkinSound
  {
    var sound:FunkinSound = new FunkinSound();

    // Clone the sound by creating one with the same data buffer.
    // Reusing the `Sound` object directly causes issues with playback.
    @:privateAccess
    sound._sound = openfl.media.Sound.fromAudioBuffer(this._sound.__buffer);

    // Call init to ensure the FlxSound is properly initialized.
    sound.init(this.looped, this.autoDestroy, this.onComplete);

    // Oh yeah, the waveform data is the same too!
    @:privateAccess
    sound._waveformData = this._waveformData;

    return sound;
  }

  /**
   * Creates a new `FunkinSound` object and loads it as the current music track.
   *
   * @param key The key of the music you want to play. Music should be at `music/<key>/<key>.ogg`.
   * @param params A set of additional optional parameters.
   *   Data should be at `music/<key>/<key>-metadata.json`.
   * @return Whether the music was started. `false` if music was already playing or could not be started
   */
  public static function playMusic(key:String, params:FunkinSoundPlayMusicParams):Bool
  {
    if (!(params.overrideExisting ?? false) && (FlxG.sound.music?.exists ?? false) && FlxG.sound.music.playing) return false;

    var suffix = params.suffix ?? '';
    var label = key + suffix;

    if (!(params.restartTrack ?? false) && FlxG.sound.music?.playing)
    {
      if (FlxG.sound.music != null && Std.isOfType(FlxG.sound.music, FunkinSound))
      {
        var existingSound:FunkinSound = cast FlxG.sound.music;
        if (existingSound._label == label)
        {
          return false;
        }
      }
    }

    if (FlxG.sound.music != null)
    {
      FlxG.sound.music.fadeTween?.cancel();
      FlxG.sound.music.stop();
      FlxG.sound.music.kill();
    }

    var pathsFunction = params.pathsFunction ?? MUSIC;
    var soundAsset:Null<openfl.media.Sound> = switch (pathsFunction)
    {
      case MUSIC:
        Paths.music(key + suffix);
      case INST:
        Paths.inst(key + suffix);
      default:
        Paths.music(key + suffix);
    }

    if (soundAsset == null)
    {
      FlxG.log.error('FunkinSound.playMusic: sound not found for key "$key"');
      return false;
    }

    emptyPartialQueue();

    var music = FunkinSound.load(soundAsset, params?.startingVolume ?? 1.0, params.loop ?? true, false, true, params.persist ?? false, params.onComplete,
      null, false, label);

    if (music != null)
    {
      setMusic(music);
      if (FlxG.sound.music != null && params.onLoad != null) params.onLoad();
      return true;
    }
    else
    {
      return false;
    }
  }

  /**
   * Replaces the Flixel current music object with the given `FunkinSound` object.
   * @param newMusic The new music to be set as the current music.
   */
  public static function setMusic(newMusic:FunkinSound):Void
  {
    FlxG.sound.music = newMusic;

    // Prevent repeat update() and onFocus() calls.
    FlxG.sound.list.remove(FlxG.sound.music);
  }

  public static function emptyPartialQueue():Void
  {
    while (partialQueue.length > 0)
    {
      @:nullSafety(Off)
      partialQueue.pop().error('Cancel loading partial sound');
    }
  }

  static var partialQueue:Array<Promise<Null<FunkinSound>>> = [];

  /**
   * Creates a new `FunkinSound` object synchronously.
   *
   * @param embeddedSound   The embedded sound resource you want to play.  To stream, use the optional URL parameter instead.
   * @param volume          How loud to play it (0 to 1).
   * @param looped          Whether to loop this sound.
   * @param group           The group to add this sound to.
   * @param autoDestroy     Whether to destroy this sound when it finishes playing.
   *                          Leave this value set to `false` if you want to re-use this `FunkinSound` instance.
   * @param autoPlay        Whether to play the sound immediately or wait for a `play()` call.
   * @param persist         Whether to keep this `FunkinSound` between states, or destroy it.
   * @param onComplete      Called when the sound finished playing.
   * @param onLoad          Called when the sound finished loading.  Called immediately for successfully loaded embedded sounds.
   * @param important       If `true`, the sound channel will forcefully be added onto the channel array, even if full. Use sparingly!
   * @return A `FunkinSound` object, or `null` if the sound could not be loaded.
  */
  // had to adjust a bit to work with our paths system hehe
  public static function load(embeddedSound:FlxSoundAsset, volume:Float = 1.0, looped:Bool = false, autoDestroy:Bool = false, autoPlay:Bool = false,
      persist:Bool = false, ?onComplete:Void->Void, ?onLoad:Void->Void, important:Bool = false, ?label:String):Null<FunkinSound>
  {
    @:privateAccess
    if (SoundMixer.__soundChannels.length >= SoundMixer.MAX_ACTIVE_CHANNELS && !important)
    {
      FlxG.log.error('FunkinSound could not play sound, channels exhausted! Found ${SoundMixer.__soundChannels.length} active sound channels.');
      return null;
    }

    var sound:FunkinSound = pool.recycle(construct);

    sound.loadEmbedded(embeddedSound, looped, autoDestroy, onComplete);

    if (label != null)
    {
      sound._label = label;
    }
    else if (embeddedSound is String)
    {
      sound._label = embeddedSound;
    }
    else
    {
      sound._label = 'unknown';
    }

    if (autoPlay) sound.play();
    sound.volume = volume;
    FlxG.sound.defaultSoundGroup.add(sound);
    sound.persist = persist;
    sound.important = important;

    FlxG.sound.list.add(sound);

    if (onLoad != null && sound._sound != null) onLoad();

    return sound;
  }

  /**
   * Will load a section of a sound file, useful for Freeplay where we don't want to load all the bytes of a song
   * @param path The path to the sound file
   * @param start The start time of the sound file
   * @param end The end time of the sound file
   * @param volume Volume to start at
   * @param looped Whether the sound file should loop
   * @param autoDestroy Whether the sound file should be destroyed after it finishes playing
   * @param autoPlay Whether the sound file should play immediately
   * @param onComplete Callback when the sound finishes playing
   * @param onLoad Callback when the sound finishes loading
   * @return A FunkinSound object
   */
  // public static function loadPartial(path:String, start:Float = 0, end:Float = 1, volume:Float = 1.0, looped:Bool = false, autoDestroy:Bool = false,
  //     autoPlay:Bool = true, ?onComplete:Void->Void, ?onLoad:Void->Void):Promise<Null<FunkinSound>>
  // {
  //   var promise:lime.app.Promise<Null<FunkinSound>> = new lime.app.Promise<Null<FunkinSound>>();

  //   // split the path and get only after first :
  //   // we are bypassing the openfl/lime asset library fuss on web only
  //   #if web
  //   path = Paths.stripLibrary(path);
  //   #end

  //   var soundRequest = FlxPartialSound.partialLoadFromFile(path, start, end);

  //   if (soundRequest == null)
  //   {
  //     promise.complete(null);
  //   }
  //   else
  //   {
  //     promise.future.onError(function(e)
  //     {
  //       soundRequest.error('Sound loading was errored or cancelled');
  //     });

  //     soundRequest.future.onComplete(function(partialSound)
  //     {
  //       var snd = FunkinSound.load(partialSound, volume, looped, autoDestroy, autoPlay, false, onComplete, onLoad);
  //       promise.complete(snd);
  //     });
  //   }

  //   return promise;
  // }

  @:nullSafety(Off)
  override public function destroy():Void
  {
    super.destroy();
    if (fadeTween != null)
    {
      fadeTween.cancel();
      fadeTween = null;
    }
    FlxTween.cancelTweensOf(this);
    this._label = 'unknown';
    this._waveformData = null;
  }

  @:access(openfl.media.Sound) @:access(openfl.media.SoundChannel) @:access(openfl.media.SoundMixer)
  override function startSound(startTime:Float)
  {
    if (!important)
    {
      super.startSound(startTime);
      return;
    }

    _time = startTime;
    _paused = false;

    if (_sound == null) return;

    // Create a channel manually if the sound is considered important.
    // var pan:Float = (SoundMixer.__soundTransform.pan + _transform.pan).clamp(-1, 1);
    var pan:Float = Math.max(-1, Math.min(1, SoundMixer.__soundTransform.pan + _transform.pan)); // we don't have a dedicated clamp function :D
    // var volume:Float = (SoundMixer.__soundTransform.volume * _transform.volume).clamp(0, MAX_VOLUME);
    var volume:Float = Math.max(0, Math.min(MAX_VOLUME, SoundMixer.__soundTransform.volume * _transform.volume));

    var audioSource:AudioSource = new AudioSource(_sound.__buffer);
    audioSource.offset = Std.int(startTime);
    audioSource.gain = volume;

    var position:lime.math.Vector4 = audioSource.position;
    position.x = pan;
    position.z = -1 * Math.sqrt(1 - Math.pow(pan, 2));
    audioSource.position = position;

    _channel = new SoundChannel(_sound, audioSource, _transform);
    _channel.addEventListener(Event.SOUND_COMPLETE, stopped);
    pitch = _pitch;
    active = true;
  }

  /**
   * Play a sound effect once, then destroy it.
   * @param key
   * @param volume
   * @return A `FunkinSound` object, or `null` if the sound could not be loaded.
   */
  public static function playOnce(key:String, volume:Float = 1.0, ?onComplete:Void->Void, ?onLoad:Void->Void, important:Bool = false, ?folder:String = "sounds"):Null<FunkinSound>
  {
    var soundAsset = switch(folder) {
      case "music": Paths.music(key);
      case "inst": Paths.inst(key);
      default: Paths.sound(key);
    }

    if (soundAsset == null) return null;

    var result:Null<FunkinSound> = FunkinSound.load(soundAsset, volume, false, true, true, false, onComplete, onLoad, important, key);
    return result;
  }

  /**
   * Stop all sounds in the pool and allow them to be recycled.
   */
  public static function stopAllAudio(musicToo:Bool = false, persistToo:Bool = false):Void
  {
    for (sound in pool)
    {
      if (sound == null) continue;
      if (!persistToo && sound.persist) continue;
      if (!musicToo && sound == FlxG.sound.music) continue;
      sound.destroy();
    }
  }

  static function construct():FunkinSound
  {
    var sound:FunkinSound = new FunkinSound();

    pool.add(sound);
    FlxG.sound.list.add(sound);

    return sound;
  }

  /**
   * Produces a string representation suitable for debugging.
   */
  override public function toString():String
  {
    return 'FunkinSound(${this._label})';
  }
}

/**
 * Additional parameters for `FunkinSound.playMusic()`
 */
typedef FunkinSoundPlayMusicParams =
{
  /**
   * The volume you want the music to start at.
   * @default `1.0`
   */
  var ?startingVolume:Float;

  /**
   * The suffix of the music file to play. Usually for "-erect" tracks when loading an INST file
   * @default ``
   */
  var ?suffix:String;

  /**
   * Whether to override music if a different track is already playing.
   * @default `false`
   */
  var ?overrideExisting:Bool;

  /**
   * Whether to override music if the same track is already playing.
   * @default `false`
   */
  var ?restartTrack:Bool;

  /**
   * Whether the music should loop or play once.
   * @default `true`
   */
  var ?loop:Bool;

  /**
   * Which Paths function to use to load a song
   * @default `MUSIC`
   */
  var ?pathsFunction:PathsFunction;

  var ?partialParams:PartialSoundParams;

  /**
   * Whether the sound should be destroyed on state switches
   */
  var ?persist:Bool;

  var ?onComplete:Void->Void;
  var ?onLoad:Void->Void;
}

typedef PartialSoundParams =
{
  var loadPartial:Bool;
  var start:Float;
  var end:Float;
}