// I hope this works.

package shaders;

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.DisplayObject;
import flash.display.Sprite;
import flash.display.StageQuality;
import flash.filters.BlurFilter;
import flash.geom.ColorTransform; 
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.utils.Dictionary;
import flash.Vector;
import flash.events.Event;
import flash.Lib;
import flash.display.PixelSnapping;
/**
 * ...
 * @author Guinin Mathieu
 */
 
/* L'objet motion blur applique automatiquement un effet de flou de vitesse à un objet en déplacement sur la scène.
 * 
 * La classe MotionBlurQuality permet d'optimiser les performances du rendu graphiques en diminuant certains paramètre :
	 * qualité de l'objet lorsqu'il est dessiné pour le flou de mouvement
	 * résulution des pixels du flou de mouvement
	 * lissage des pixels dans le rendu final du flou
	 * ...
 */
class MotionBlur extends Bitmap
{
	static public var maxMilisecond:Int = 20;
	
	
	static public function activer() {
		Lib.current.addEventListener(Event.RENDER, actualise, false, -10) ;
		Lib.current.addEventListener(Event.ENTER_FRAME, call_invalidate) ;
	}
	static public function desactiver() { 
		Lib.current.removeEventListener(Event.RENDER, actualise) ;
		Lib.current.removeEventListener(Event.ENTER_FRAME, call_invalidate) ;
	}
	
	static var listeMotionBlur:List<MotionBlur> = {
		activer();
		new List<MotionBlur>();
	}
	
	public var reference:DisplayObject;
	public var lux:ColorTransform;
	public var quality:MotionBlurQuality;
	public var refresh:Bool;
	
	public function new(reference, ?quality:MotionBlurQuality,?lumiere:Float = 1) {
		super(null, PixelSnapping.AUTO, quality.smooth);
		this.quality = MotionBlurQuality.HIGH;
		this.reference = reference;
		lux = new ColorTransform();
		source_lumiere(lumiere);
		if (reference.parent == null) reference.addEventListener(Event.ADDED_TO_STAGE, added);
		else {
			reference.parent.addChildAt(this, reference.parent.getChildIndex(reference));
			reference.addEventListener(Event.REMOVED_FROM_STAGE, removed);
			added(null);
		}
		pp = new Point(reference.x, reference.y);
		vp = new Point(0, 0);
	}
	
	static function actualise(e:Event) {
		for (blur in listeMotionBlur) {
			blur.prepar();
			if (blur.changements()) {
				blur.drawBlur();
			}
		}
		Lib.current.stage.invalidate();
	}
	
	static function call_invalidate(e:Event) {
		Lib.current.stage.invalidate();
	}
	
	
	public function source_lumiere(intensite:Float) {
		lux.alphaMultiplier = intensite;
	}
	
	public function teleport() {
		pp = new Point(reference.x, reference.y);
	}
	
	
	public function delete() {
		bitmapData.dispose();
		removed(null);
		reference.removeEventListener(Event.ADDED_TO_STAGE, added);
		reference.removeEventListener(Event.REMOVED_FROM_STAGE, removed);
	}
	
	function added(e:Event) {
		reference.parent.addChildAt(this, reference.parent.getChildIndex(reference));
		reference.addEventListener(Event.REMOVED_FROM_STAGE, removed);
		MotionBlur.listeMotionBlur.add(this);
	}
	
	function removed(e:Event) {
		if (parent != null) parent.removeChild(this);
		reference.addEventListener(Event.ADDED_TO_STAGE, added);
		MotionBlur.listeMotionBlur.remove(this);
	}
	
	
	
	var w:Int ;
	var h:Int ;
	var pp:Point; // position précédente de la référence
	var vp:Point; // vitesse dessiné du flou dans le référentiel coïncident de l'objet
	var vit:Point; // vitesse réel de l'objet dans le référentiel coïncident de l'objet
	var longueur:Int;
	
	function prepar() {
		
		var pos:Point = reference.localToGlobal(new Point(0, 0));
		vit = pos.subtract(pp);
		pp = pos;
		var cos = vit.x / vit.length;
		var sin = vit.y / vit.length;
		
		
		var inv_parent = reference.parent.transform.concatenatedMatrix;
		inv_parent.invert();
		
		var matDim:Matrix = new Matrix();
		matDim.scale(quality.scaleX, quality.scaleY);		// on dimentionne la résolution réel souhaité
		matDim.concat(new Matrix(cos, sin, -sin, cos));		// on fait pivoter le tout dans le sens du mouvement
		matDim.concat(inv_parent);							// on annule le redimentionnement futur dû au parent
		transform.matrix = matDim ;	
		
		var rect = reference.getRect(this);
		var p = matDim.transformPoint(rect.topLeft); 		// coordonnées du coin supérieur droit de reference relativement au parent
		x = p.x - vit.x ;
		y = p.y - vit.y ;								// this est placé à la dernière position réel de reference relativement au parent
		
		longueur = Std.int(vit.length / quality.scaleX);
		w = Std.int(rect.width + longueur) ; 
		h = Std.int(rect.height) ;
		
	}
	
	function changements() {
		if (!refresh && vit.length < quality.minSpeed) {
			reference.visible = true;
			visible = false;
			return false;
		} else {
			reference.visible = quality.objectVisible;
			visible = true;
			if (refresh || vit.subtract(vp).length/vit.length > quality.tolerance) {
				refresh = false;
				vp = vit;
				return true;
			} else return false;
		}
	}
	
	function drawBlur() {
		
		if (bitmapData != null) bitmapData.dispose();
		bitmapData = new BitmapData(w, h, true, 0);
		
		var tempFilters = reference.filters;
		var tempQuality = reference.stage.quality;
		reference.stage.quality = quality.stageQuality;
		tempFilters.push(new BlurFilter(longueur, 0, 1));
		reference.filters = tempFilters ;
		
		var inv_bmp = transform.concatenatedMatrix;
		inv_bmp.invert();
		inv_bmp.translate(-longueur/2,0);
		var location_in_bmp = reference.transform.concatenatedMatrix;
		location_in_bmp.concat(inv_bmp);
		
		bitmapData.draw(reference, location_in_bmp, lux, null, null, quality.smooth);
		
		tempFilters.pop();
		reference.filters = tempFilters;
		reference.stage.quality = tempQuality;
	}
}

class MotionBlurQuality 
{
	public var scaleX:Int;
	public var scaleY:Int;
	public var stageQuality:StageQuality;
	public var minSpeed:Float;
	public var tolerance:Float;
	public var smooth:Bool;
	public var objectVisible:Bool;
	public var maxMilisecond:Int ;
	
	
	public function new(scaleX = 2,
						scaleY = 1,
						stageQuality = StageQuality.LOW,
						minSpeed = 30,
						tolerance = 0.1,
						smooth = false,
						objectVisible = false,
						maxMilisecond=0xffffffff) {
		this.scaleY = scaleY;
		this.scaleX = scaleX;
		this.stageQuality = stageQuality;
		this.minSpeed = minSpeed;
		this.tolerance = tolerance;
		this.smooth = smooth;
		this.objectVisible = objectVisible;
		this.maxMilisecond = maxMilisecond;
	}
	
	static public var LOW = new MotionBlurQuality(3, 6, StageQuality.LOW, 50,0.3, false);
	static public var MEDIUM = new MotionBlurQuality(2, 4, StageQuality.LOW, 20,0.2, false);
	static public var HIGH = new MotionBlurQuality(1, 2, StageQuality.LOW, 10,0.1, false);
	static public var MAX = new MotionBlurQuality(1, 1, StageQuality.HIGH, 2,0.01, true);
}
