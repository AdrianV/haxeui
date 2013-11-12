package haxe.ui.toolkit.styletemplates;

/**
 * ...
 * @author 
 */

typedef RuleIteratorResult = {
	prefix: String,
	content: String,
	delim: String,
}
 
class RuleIterator
{
	private var _ns: Int;
	private var _ne: Int;
	private var _ndelim: Int;
	private var _content: String;
	private var _expectdd: Bool;
	
		
	public function new(content: String, expectDoubleDot: Bool) {
		_content = content;
		_ns = 0;
		_ne = 0;
		_expectdd = expectDoubleDot;
	}
	
	private function parseEndOf(start: Int): Int {
		var first = start;
		if (first == -1) return -1;
		var n = first + 1;
		var nClose: Int = _content.indexOf("}", n);
		var nOpen: Int = _content.indexOf("{", n);
		var xOpen = 0;
		do {
			while (nOpen != -1 && nOpen < nClose) {
				xOpen ++;
				n = nOpen + 1;
				nOpen = _content.indexOf("{", n);
			}
			while (nClose != -1 && (nClose < nOpen || nOpen == -1)) {
				xOpen --;
				if (xOpen < 0) {
					return nClose;
				}
				n = nClose + 1;
				nClose = _content.indexOf("}", n);
			}
		} while (nOpen != -1 && nClose != -1);
		return -1;
	}

	public function hasNext(): Bool {
		if (_ns != -1) {
			var nd = _expectdd ? _content.indexOf(":", _ns) : -1;
			var nc = _expectdd ? _content.indexOf(";", _ns) : -1;
			var np = _content.indexOf("{", _ns);
			if (nd != -1 && (nd < np || np == -1)) {
				_ndelim = nd;
				//var nc = _content.indexOf(";", nd);
				if (nc == -1) {
					_ns = -1;
				} else if (nc < nd) {
					_ne = nc;
					_ndelim = nc;
				} else if (nc < np || np == -1) {
					_ne = nc;
				} else {
					do {
						var npe = parseEndOf(np);
						if (npe != -1) {
							nc = _content.indexOf(";", npe);
							np = _content.indexOf("{", npe);
						}
					} while (nc != -1 && np != -1 && nc > np);
					_ne = nc;
				}
			} else if (np != -1 && (np < nd || nd == -1)) {
				_ndelim = np;
				_ne = parseEndOf(np);
			} else if (nc != -1) {
				_ndelim = nc;
				_ne = nc;
			} else {
				_ns = -1;
			}
		}
		return _ns != -1 ;
	}
	
	public function next() : RuleIteratorResult {
		var res: RuleIteratorResult = { prefix: StringTools.trim(_content.substring(_ns, _ndelim)), content: null, delim: _content.charAt(_ndelim) };
		if (_ne != -1) {
			res.content = StringTools.trim(_content.substr(_ndelim + 1, _ne - _ndelim - 1));
			_ns = _ne + 1;
		} else {
			res.content = StringTools.trim(_content.substring(_ndelim + 1));
			_ns = -1;
		}
		return res;
	}
	
}
