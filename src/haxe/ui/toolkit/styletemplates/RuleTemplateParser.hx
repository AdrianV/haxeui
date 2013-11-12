package haxe.ui.toolkit.styletemplates;

import haxe.ui.toolkit.styletemplates.RuleIterator;

typedef RuleTemplateParam = {
	name: String,
	def: String,
}

typedef RuleTemplate = {
	name: String,
	content: String,
	params: Array<RuleTemplateParam>,
}
 
class RuleTemplateParser
{

	static public function parse(line: RuleIteratorResult): RuleTemplate {
		var template: RuleTemplate = {
			name: null,
			content: line.content,
			params: new Array(),
		}
		var name = line.prefix;
		if ( name.charAt(0) == "@" ) name = name.substring(1);
		var pOpen = name.indexOf("(");
		if (pOpen >= 0) {
			var pClose = name.lastIndexOf(")");
			if (pClose > pOpen) {
				var params = name.substring(pOpen + 1, pClose).split(",");
				name = name.substring(0, pOpen);
				for (p in params) {
					var pos = p.indexOf("=");
					var def = "";
					if (pos == -1) {
						pos = p.indexOf(":");
					} else {
						def = p.substring(pos + 1);
					}
					var vname = (pos >= 0) ? p.substring(0, pos): p;
					vname = name + "__" + (vname.charAt(0) == "@" ? vname.substring(1): vname);
					template.params.push({name: vname, def: def});
				}
			} else {
				trace('warning $name has open parenthesis');
				name = name.substring(0, pOpen);
			}
		}		
		template.name = name;
		return template;
	}
	
}