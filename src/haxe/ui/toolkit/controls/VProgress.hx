package haxe.ui.toolkit.controls;

import haxe.ui.toolkit.core.interfaces.Direction;
import haxe.ui.toolkit.core.interfaces.IClonable;
import haxe.ui.toolkit.core.interfaces.IDisplayObject;
import haxe.ui.toolkit.layout.Layout;

/**
 Vertical progress bar control
 
 <b>Events:</b>
 
 * `Event.CHANGE` - Dispatched when value of the progess bar has changed
 **/
 
class VProgress extends Progress implements IClonable<VProgress> {
	public function new() {
		super();
		direction = Direction.VERTICAL;
	}
	
	//******************************************************************************************
	// Clone
	//******************************************************************************************
	public override function self():VProgress return new VProgress();
	public override function clone():VProgress {
		var c:VProgress = cast super.clone();
		return c;
	}
}
