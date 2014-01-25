package haxe.ui.toolkit;

import haxe.ui.toolkit.core.XMLController;
import haxe.ui.toolkit.events.UIEvent;
import haxe.ui.toolkit.util.StringUtil;

@:build(haxe.ui.toolkit.core.Macros.buildController("assets/test.xml"))
class TestController extends XMLController {
	public function new() {
		/*
		testButton.addEventListener(UIEvent.CLICK, function (e) {
			trace("clicked");
		});
		*/
		
		testButton.onClick = function(e:UIEvent) {
			e.component.text = "bob";
			trace("click 2");
		};
		
		testButton.onMouseOver = function(e:UIEvent) {
			trace("over");
		};
	}
	
}