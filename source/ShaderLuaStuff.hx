Lua_helper.add_callback(lua, "addEffect", function(camera:String,effect:String, ?val1:Dynamic, ?val2:Dynamic, ?val3:Dynamic) {
	PlayState.instance.addShaderToCamera(camera, getEffectFromString(effect, val1, val2, val3));		
});
Lua_helper.add_callback(lua, "clearEffects", function(camera:String) {
	PlayState.instance.clearShaderFromCamera(camera);
});

function getEffectFromString(?effect:String = '', ?val1:Dynamic, ?val2:Dynamic, ?val3:Dynamic , ?val4:Dynamic = ""):ShaderEffect {
	switch(effect.toLowerCase().trim()) {
		case 'grayscale' | 'greyscale' : return new GreyscaleEffect();
		case 'oldtv' : return new OldTVEffect();
		case 'invert' | 'invertcolor': return new InvertColorsEffect();
		case 'tiltshift': return new TiltshiftEffect(val1,val2);
		case 'grain': return new GrainEffect(val1,val2,val3);
		case 'scanline': return new ScanlineEffect(val1);
		case 'outline': return new OutlineEffect(val1, val2, val3, val4);
		case 'distortion': return new DistortBGEffect(val1, val2, val3);
		case 'vcr': return new VCRDistortionEffect(val1,val2,val3,val4);
		case 'glitch': return new GlitchEffect(val1, val2, val3);
		case 'vcr2': return new VCRDistortionEffect2(); //the tails doll one
		case '3d': return new ThreeDEffect(val1, val2, val3, val4);
		case 'bloom': return new BloomEffect(val1/512.0,val2);
		case 'rgbshiftglitch' | 'rgbshift': return new RGBShiftGlitchEffect(val1, val2);
		case 'pulse': return new PulseEffect(val1,val2,val3);
		case 'chromaticabberation' | 'ca': return new ChromaticAberrationEffect(val1);
		case 'sketch': return new SketchEffect();
		case 'desaturation': return new DesaturationEffect(val1);
		case 'fisheye': return new FishEyeEffect(val1);
	}
	return new GreyscaleEffect();
}