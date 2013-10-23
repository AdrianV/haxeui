package haxe.ui.toolkit.core;

import haxe.macro.Context;
import haxe.macro.Expr;

typedef RuleTemplate = {
	content: String,
	params: Array<String>,
	def: Array<String>,
}

typedef CodePart = {
	var_part: String,
	code_part: String,
}

class Macros {
	
	private static function getNextRule(content: String, start: Int): {rule: String, content: String, end: Int} {
		var first = content.indexOf("{", start);
		if (first == -1) return {rule: "", content: "", end: -1};
		var n = first + 1;
		var nClose: Int = content.indexOf("}", n);
		var nOpen: Int = content.indexOf("{", n);
		var xOpen = 0;
		do {
			while (nOpen != -1 && nOpen < nClose) {
				xOpen ++;
				n = nOpen + 1;
				nOpen = content.indexOf("{", n);
			}
			while (nClose != -1 && (nClose < nOpen || nOpen == -1)) {
				xOpen --;
				if (xOpen < 0) {
					return {rule: StringTools.trim(content.substring(start, first)), content: content.substring(first + 1, nClose), end: nClose + 1};
				}
				n = nClose + 1;
				nClose = content.indexOf("}", n);
			}
		} while (nOpen != -1 && nClose != -1);
		return {rule: StringTools.trim(content.substring(start, first)), content: content.substring(first + 1), end: -1};
	}
	
	private static var ruleTemplates: Map<String, RuleTemplate>;
	private static var ruleVars: Map<String, Void>;
	
	private static function parseGlobal(content: String): String {
		var res = "";
		var lines = new LineIterator(content);
		for (line in lines) {
			var pos = line.indexOf("{");
			if (pos == -1) {
				pos = line.indexOf(":");
				if (pos >= 0) {
					var name = StringTools.trim(line.substring(0, pos));
					if (! ruleVars.exists(name)) {
						res += "var ";
						ruleVars.set(name, null);
					}
					res += name + " = " + StringTools.trim(line.substring(pos + 1)) + "\n";
				}
			} else {
				var part = getNextRule(content, lines.pos);
				var template: RuleTemplate = {
					content: null,
					params: new Array(),
					def: new Array(),
				}
				var name = part.rule;
				if ( name.charAt(0) != "@" ) name = "@" + name;
				var pOpen = name.indexOf("(");
				if (pOpen >= 0) {
					var pClose = name.lastIndexOf(")");
					if (pClose > pOpen) {
						var params = name.substring(pOpen + 1, pClose).split(",");
						name = name.substring(0, pOpen);
						for (p in params) {
							pos = p.indexOf("=");
							var def = "";
							if (pos == -1) {
								pos = p.indexOf(":");
							} else {
								def = p.substring(pos);
							}
							var vname = (pos >= 0) ? p.substring(0, pos): p;
							vname = name.substring(1) + "__" + (vname.charAt(0) == "@" ? vname.substring(1): vname);
							res += 'var $vname' + (pos >= 0 ? p.substring(pos) : ": Dynamic");
							res += ";\n";
							template.params.push(vname);
							template.def.push(def);
						}
					} else {
						trace('warning $name has open parenthesis');
						name = name.substring(0, pOpen);
					}
					
				}
				template.content = StringTools.replace(part.content, "@", name.substring(1) + "__");
				ruleTemplates.set(name, template);
				lines.goto(part.end);
			}
		} 
		//trace(res);
		return res;
	}
	
	macro public static function addStyleSheet(resourcePath:String):Expr {
		ruleTemplates = new Map();
		ruleVars = new Map();
		if (sys.FileSystem.exists(resourcePath) == false) {
			var paths:Array<String> = Context.getClassPath();
			for (path in paths) {
				path = path + "/" + resourcePath;
				if (sys.FileSystem.exists(path)) {
					resourcePath = path;
					break;
				}
			}
		}
		
		var contents:String = sys.io.File.getContent(resourcePath);
		var code:String = "function() {\n";
		var x = 0;
		while (x != -1) {
			var part = getNextRule(contents, x);
			if (part.rule != "") {
				if (part.rule == "@") {
					code += parseGlobal(part.content);
				} else {
					var style = StringTools.replace(part.content, "\"", "\\\"");
					code += "\tMacros.addStyle(\"" + part.rule + "\", \"" + style + "\");\n";
				}
			}
			x = part.end;
		}
		code += "}()\n";
		//trace(code);
		return Context.parseInlineString(code, Context.currentPos());
	}
	
	private static function codeStyleData(styleData: String): CodePart {
		var res = { var_part: "", code_part: "" };
		if (styleData.length > 0) {
			var props:Array<String> = styleData.substr(0, styleData.length-1).split(":");
			var propName:String = StringTools.trim(props[0]);
			if (StringTools.startsWith(propName, "@")) {
				var pOpen = propName.indexOf("(");
				var pClose = propName.indexOf(")");
				var name = (pOpen >= 0) ? propName.substring(0, pOpen) : propName;
				var template = ruleTemplates.get(name);
				var i = 0;
				if (pOpen >= 0 && pClose > pOpen) {
					var params = propName.substring(pOpen + 1, pClose).split(",");
					while (i < params.length && i < template.params.length) {
						res.var_part += template.params[i] + " = " + params[i] + ";\n";
						i++;
					}
				}
				while (i < template.params.length) {
					if (template.def[i] != "") {
						res.var_part += template.params[i] + template.def[i] + ";\n";
					}
					i++;
				}					
				if (template != null) {
					var lines = new LineIterator(template.content);
					
					for (line in lines) {
						res.code_part += codeStyleData(line).code_part;
					}
					//trace(res.var_part + res.code_part);
				} else {
					trace('warning template $propName not found !');
					//trace(ruleTemplates);
				}
			} else if (props.length > 1) {
				var propValue:String = StringTools.trim(props[1]);
				
				if (propName == "width" && propValue.indexOf("%") != -1) { // special case for width
					propName = "percentWidth";
					propValue = propValue.substr(0, propValue.length - 1);
				} else if (propName == "height" && propValue.indexOf("%") != -1) { // special case for height
					propName = "percentHeight";
					propValue = propValue.substr(0, propValue.length - 1);
				} else if (propName == "filter") {
					var filterParams = "";
					var n:Int = propValue.indexOf("(");
					if (n != -1) {
						filterParams = propValue.substring(n + 1, propValue.length - 1);
					}
					if (StringTools.startsWith(propValue, "dropShadow")) {
						propValue = "new flash.filters.DropShadowFilter(" + filterParams + ")";
					} else if (StringTools.startsWith(propValue, "blur")) {
						propValue = "new flash.filters.BlurFilter(" + filterParams + ")";
					} else if (StringTools.startsWith(propValue, "glow")) {
						propValue = "new flash.filters.GlowFilter(" + filterParams + ")";
					} else {
						propValue = "null";
					}
				} else if (propName == "backgroundImageScale9") {
					var coords:Array<String> = propValue.split(",");
					var x1:Int = Std.parseInt(coords[0]);
					var y1:Int = Std.parseInt(coords[1]);
					var x2:Int = Std.parseInt(coords[2]);
					var y2:Int = Std.parseInt(coords[3]);
					propValue = "new flash.geom.Rectangle(" + x1 + "," + y1 + "," + (x2 - x1) + "," + (y2 - y1) + ")";
				} else if (propName == "backgroundImageRect") {
					var arr:Array<String> = propValue.split(",");
					propValue = "new flash.geom.Rectangle(" + Std.parseInt(arr[0]) + "," + Std.parseInt(arr[1]) + "," + Std.parseInt(arr[2]) + "," + Std.parseInt(arr[3]) + ")";
				}
				
				if (StringTools.startsWith(propValue, "#")) { // lazyness
					propValue = "0x" + propValue.substr(1, propValue.length - 1);
				}
				
				res.code_part = "\t\t" + propName + ":" + propValue + ",\n";
			}
		}		
		return res;
	}
	
	macro public static function addStyle(rule:String, style:String):Expr {
		var code: CodePart = { var_part: "", code_part: ""};
		
		code.code_part += "\tvar style:haxe.ui.toolkit.style.Style = new haxe.ui.toolkit.style.Style({\n";
		var lines = new LineIterator(style);
		for (styleData in lines) {
			var x = codeStyleData(styleData);
			code.code_part += x.code_part;
			code.var_part += x.var_part;
		}
		code.code_part += "\t});\n";
		code.code_part += "\thaxe.ui.toolkit.style.StyleManager.instance.addStyle(\"" + rule + "\", style);\n";
				
		var s = "function() {\n" + code.var_part + code.code_part  + "}()\n";
		//trace(s);
		return Context.parseInlineString(s, Context.currentPos());
	}
	
	macro public static function registerComponentPackage(pack:String, prefix:String):Expr {

		var code:String = "function() {\n";
		var currentClassName:String = Context.getLocalClass().toString();
		var arr:Array<String> = pack.split(".");
		var paths:Array<String> = Context.getClassPath();
		
		for (path in paths) {
			var dir:String = path + arr.join("/");
			if(!sys.FileSystem.exists(dir) || !sys.FileSystem.isDirectory(dir)) {
				continue;
			}
			trace(dir);
			var files:Array<String> = sys.FileSystem.readDirectory(dir);
			if (files != null) {
				for (file in files) {
					if (file.indexOf(".hx") != -1) {
						var name:String = file.substr(0, file.length - 3);
						var path:String = Context.resolvePath(dir + "/" + file);
						
						var types:Array<haxe.macro.Type> = Context.getModule(pack + "." + name);
						
						for (t in types) {
							var className:String = getClassNameFromType(t);
							if (hasInterface(t, "haxe.ui.toolkit.core.interfaces.IDisplayObject")) {
								if (className == pack + "." + name) {
									if (currentClassName.indexOf("ClassManager") != -1) {
										code += "\tregisterComponentClass(" + className + ", '" + name.toLowerCase() + "', '" + prefix + "');\n";
									} else {
										code += "\tClassManager.instance.registerComponentClass(" + className + ", '" + name.toLowerCase() + "', '" + prefix + "');\n";
									}
								}
							}
						}
					}
				}
			}
		}
		
		code += "}()\n";
		//trace(code);
		return Context.parseInlineString(code, Context.currentPos());
	}
	
	macro public static function registerDataSourcePackage(pack:String):Expr {
		
		var code:String = "function() {\n";
		var currentClassName:String = Context.getLocalClass().toString();
		var arr:Array<String> = pack.split(".");
		var paths:Array<String> = Context.getClassPath();

		for (path in paths) {
			var dir:String = path + arr.join("/");
			if(!sys.FileSystem.exists(dir) || !sys.FileSystem.isDirectory(dir)) {
				continue;
			}
			var files:Array<String> = sys.FileSystem.readDirectory(dir);
			if (files != null) {
				for (file in files) {
					if (file.indexOf(".hx") != -1) {
						var name:String = file.substr(0, file.length - 3);
						var path:String = Context.resolvePath(dir + "/" + file);
						
						var types:Array<haxe.macro.Type> = Context.getModule(pack + "." + name);
						
						for (t in types) {
							var className:String = getClassNameFromType(t);
							if (hasInterface(t, "haxe.ui.toolkit.data.IDataSource")) {
								if (className == pack + "." + name) {
									name = StringTools.replace(name, "DataSource", "");
									if (name.length > 0) {
										if (currentClassName.indexOf("ClassManager") != -1) {
											code += "\tregisterDataSourceClass(" + className + ", '" + name.toLowerCase() + "');\n";
										} else {
											code += "\tClassManager.instance.registerDataSourceClass(" + className + ", '" + name.toLowerCase() + "');\n";
										}
									}
								}
							}
						}
					}
				}
			}
		}
		
		code += "}()\n";
		//trace(code);
		return Context.parseInlineString(code, Context.currentPos());
	}
	
	private static function getClassNameFromType(t:haxe.macro.Type):String {
		var className:String = "";
		switch (t) {
				case TAnonymous(t): className = t.toString();
				case TMono(t): className = t.toString();
				case TLazy(t): className = "";
				case TFun(t, _): className = t.toString();
				case TDynamic(t): className = "";
				case TInst(t, _): className = t.toString();
				case TEnum(t, _): className = t.toString();
				case TType(t, _): className = t.toString();
				case TAbstract(t, _): className = t.toString();
		}
		return className;
	}
	
	private static function hasInterface(t:haxe.macro.Type, interfaceRequired:String):Bool {
		var has:Bool = false;
		switch (t) {
				case TAnonymous(t): {};
				case TMono(t): {};
				case TLazy(t): {};
				case TFun(t, _): {};
				case TDynamic(t): {};
				case TInst(t, _): {
					while (t != null) {
						for (i in t.get().interfaces) {
							var interfaceName:String = i.t.toString();
							if (interfaceName == interfaceRequired) {
								has = true;
								break;
							}
						}
						
						if (has == false) {
							if (t.get().superClass != null) {
								t = t.get().superClass.t;
							} else {
								t = null;
							}
						} else {
							break;
						}
					}
				}
				case TEnum(t, _): {};
				case TType(t, _): {};
				case TAbstract(t, _): {};
		}
		
		return has;
	}
}


private class LineIterator {
	
	private var _ns: Int;
	private var _ne: Int;
	private var _content: String;
	public var pos(default, null): Int;
	public function new(content: String) {
		_content = content;
		_ns = 0;
		_ne = 0;
	}
	
	public inline function hasNext(): Bool {
		if (_ne != -1 && _ns != -1) _ne = _content.indexOf(";", _ns);
		return _ne != -1 && _ns != -1 ;
	}
	
	public inline function next() : String {
		var res = (_ne == -1) ? _content.substring(_ns) : _content.substring(_ns, _ne +1);
		pos = _ns;
		_ns = _ne + 1;
		return StringTools.trim(res);
	}
	
	public inline function goto(start: Int) _ns = start;
}