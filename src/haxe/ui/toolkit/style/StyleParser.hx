package haxe.ui.toolkit.style;

import flash.geom.Rectangle;
import flash.Lib;
import haxe.ui.toolkit.util.FilterParser;
import hscript.Interp;
import hscript.Parser;
import haxe.ui.toolkit.style.RuleTemplateParser;

class StyleParser {
	
	private static var _parser: Parser;
	private static var _interp: Interp;
	private static var _ruleTemplates: Map<String, RuleTemplate>;

	private static function parseGlobal(content: String) {
		var lines = new RuleIterator(content, true);
		for (line in lines) {
			if (line.delim == ":") {
				_interp.variables.set(line.prefix, _interp.execute(_parser.parseString(line.content)));
			} else if (line.delim == "{") {
				var template = RuleTemplateParser.parse(line);
				_ruleTemplates.set(template.name, template);
			}
		}
	}
	
	private static function parseStyle(content: String): Style {
		var style = new Style();
		var lines = new RuleIterator(content, true);
		function setStyleProperty(propName: String, propValue: String) {
			if (propName.charAt(0) == "@") {
				var pOpen = propName.indexOf("(");
				var pClose = propName.indexOf(")");
				var name = (pOpen >= 0) ? propName.substring(1, pOpen) : propName.substring(1);
				var template = _ruleTemplates.get(name);
				if (template != null) {
					var i = 0;
					if (pOpen >= 0 && pClose > pOpen) {
						var params = propName.substring(pOpen + 1, pClose).split(",");
						while (i < params.length && i < template.params.length) {
							_interp.variables.set(template.params[i].name, _interp.execute(_parser.parseString(params[i])));
							i++;
						}
					}
					while (i < template.params.length) {
						var param = template.params[i];
						if (param.def != "") {
							_interp.variables.set(param.name, _interp.execute(_parser.parseString(param.def)));
						}
						i++;
					}					
					var lines = new RuleIterator(StringTools.replace(template.content, "@", template.name + "__"), true);
					
					for (line in lines) {
						setStyleProperty(line.prefix, line.content);
					}
				} else {
					trace('warning template $propName not found !');
				}
				return;
			}
			if (Reflect.field(style, "set_" + propName) == null) {
				trace("Warning: " + propName + " no found");
				return;
			}
			//propValue = StringTools.replace(propValue, "\"", "");
			//propValue = StringTools.replace(propValue, "'", "");
			if (propName == "width" && propValue.indexOf("%") != -1) { // special case for width
				propName = "percentWidth";
				propValue = propValue.substr(0, propValue.length - 1);
			} else if (propName == "height" && propValue.indexOf("%") != -1) { // special case for height
				propName = "percentHeight";
				propValue = propValue.substr(0, propValue.length - 1);
			} else if (propName == "filter") {
				style.filter = FilterParser.parseFilter(propValue);
				return;
			} else if (propName == "backgroundImageScale9") {
				var coords:Array<String> = propValue.split(",");
				var x1:Int = Std.parseInt(coords[0]);
				var y1:Int = Std.parseInt(coords[1]);
				var x2:Int = Std.parseInt(coords[2]);
				var y2:Int = Std.parseInt(coords[3]);
				var scale9:Rectangle = new Rectangle();
				scale9.left = x1;
				scale9.top = y1;
				scale9.right = x2;
				scale9.bottom = y2;
				style.backgroundImageScale9 = scale9;
				return;
			} else if (propName == "backgroundImageRect") {
				var arr:Array<String> = propValue.split(",");
				style.backgroundImageRect = new Rectangle(Std.parseInt(arr[0]), Std.parseInt(arr[1]), Std.parseInt(arr[2]), Std.parseInt(arr[3]));
				return;
			}
			if (propValue.charAt(0) == "#") propValue = "0x" + propValue.substr(1, propValue.length - 1);
			try {
				Reflect.setProperty(style, propName, _interp.execute(_parser.parseString(propValue)));
			} catch (e: Dynamic) {
				//trace( { n:propName, v: propValue } );
				Reflect.setProperty(style, propName, propValue); // try to set property value as string
			}
		}
		for (line in lines) {
			setStyleProperty(line.prefix, line.content);
		}
		return style;
	}
	
	public static function fromString(styleString:String):Styles {
		if (styleString == null || styleString.length == 0) {
			return new Styles();
		}
		
		var styles = new Styles();
		_parser = new Parser();
		_interp = new Interp();
		_ruleTemplates = new Map();
		var rules = new RuleIterator(styleString, false);
		for (rule in rules) {
			if (rule.prefix == "@") {
				parseGlobal(rule.content);
			} else {
				var style = parseStyle(rule.content);
				if (rule.prefix.indexOf(",") == -1) {
					styles.addStyle(rule.prefix, style);
				} else {
					var arr:Array<String> = rule.prefix.split(",");
					for (s in arr) {
						s = StringTools.trim(s);
						styles.addStyle(s, style);
					}
				}
			}
		}
		
		return styles;
	}
}