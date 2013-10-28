package haxe.ui.toolkit.style;

import haxe.ui.toolkit.style.RuleIterator;

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
			name: line.prefix,
			content: line.content,
			params: new Array(),
		}
		if ( template.name.charAt(0) == "@" ) template.name = template.name.substring(1);
		var pOpen = template.name.indexOf("(");
		if (pOpen >= 0) {
			var pClose = template.name.lastIndexOf(")");
			if (pClose > pOpen) {
				var params = template.name.substring(pOpen + 1, pClose).split(",");
				template.name = template.name.substring(0, pOpen);
				for (p in params) {
					var pos = p.indexOf("=");
					var def = "";
					if (pos == -1) {
						pos = p.indexOf(":");
					} else {
						def = p.substring(pos + 1);
					}
					var vname = (pos >= 0) ? p.substring(0, pos): p;
					vname = template.name + "__" + (vname.charAt(0) == "@" ? vname.substring(1): vname);
					template.params.push({name: vname, def: def});
				}
			} else {
				trace('warning $template.name has open parenthesis');
				template.name = template.name.substring(0, pOpen);
			}
		}		
		return template;
	}
	
}