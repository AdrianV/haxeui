package haxe.ui.toolkit.controls;

import haxe.ui.toolkit.core.Component;
import haxe.ui.toolkit.core.interfaces.Direction;
import haxe.ui.toolkit.core.interfaces.IDirectional;

/**
 Scrollbar control
 
 <b>Events:</b>
 
 * `Event.CHANGE` - Dispatched when value of the scrollbar has changed
 **/
class Scroll extends Component implements IDirectional {
	private var _direction:String = Direction.VERTICAL;
	
	public function new() {
		super();
	}
	
	//******************************************************************************************
	// ProgressBar methods/properties
	//******************************************************************************************
	/**
	 The direction of this progress bar. Can be `horizontal` or `vertical`
	 **/
	public var direction(get, set):String;
	
	private function get_direction():String {
		return _direction;
	}
	
	private function set_direction(value:String):String {
		_direction = value;
		return value;
	}
}