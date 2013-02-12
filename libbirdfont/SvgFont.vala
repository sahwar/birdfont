/*
    Copyright (C) 2013 Johan Mattsson

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

using Xml;

namespace BirdFont {

class SvgFont : GLib.Object {
	Font font;
	double units = 1;
	double font_advance = 0;
	
	public SvgFont (Font f) {
		this.font = f;
	}
	
	public void load (string path) {
		Xml.Doc* doc;
		Xml.Node* root = null;
		
		Parser.init ();
		
		doc = Parser.parse_file (path);
		root = doc->get_root_element ();
		return_if_fail (root != null);
		parse_svg_font (root);

		delete doc;
		Parser.cleanup ();
	}
	
	void parse_svg_font (Xml.Node* node) {
		for (Xml.Node* iter = node->children; iter != null; iter = iter->next) {
			if (iter->name == "defs") {
				parse_svg_font (iter);
			}
			
			if (iter->name == "font") {
				parse_font_tag (iter);
				parse_svg_font (iter);
			}

			if (iter->name == "font-face") {
				parse_font_limits (iter);
			}

			if (iter->name == "hkern") {
				parse_hkern (iter);
			}
									
			if (iter->name == "glyph") {
				parse_glyph (iter);
			}
		}		
	}

	void parse_hkern (Xml.Node* node) {
		string left = "";
		string right = "";
		string left_name = "";
		string right_name = "";
		double kerning = 0;
		unichar l, r;
		StringBuilder sl, sr;
		string attr_name = "";
		string attr_content;
		
		for (Xml.Attr* prop = node->properties; prop != null; prop = prop->next) {
			attr_name = prop->name;
			attr_content = prop->children->content;
			
			// left
			if (attr_name == "u1") {
				left = attr_content;
			}	
					
			// right	
			if (attr_name == "u2") {
				right = attr_content;
			}

			if (attr_name == "g1") {
				left_name = attr_content;
			}
			
			if (attr_name == "g2") {
				right_name = attr_content;
			}
				
			// kerning
			if (attr_name == "k") {
				kerning = double.parse (attr_content);
			}
		}
		
		
		// TODO: ranges and sequences for u1 & u2 + g1 & g2
		foreach (string lk in left.split (",")) {
			foreach (string rk in right.split (",")) {
				l = get_unichar (lk);
				r = get_unichar (rk);
				
				sl = new StringBuilder ();
				sl.append_unichar (l);
				
				sr = new StringBuilder ();
				sr.append_unichar (r);
				
				font.set_kerning (sl.str, sr.str, -kerning);				
			}
		}
	}

	void parse_font_limits (Xml.Node* node) {
		string attr_name = "";
		string attr_content;
		double top_limit = 0;
		double bottom_limit = 0;
		
		for (Xml.Attr* prop = node->properties; prop != null; prop = prop->next) {
			attr_name = prop->name;
			attr_content = prop->children->content;
			
			if (attr_name == "units-per-em") {
				units = 100.0 / double.parse (attr_content);
			}	
						
			if (attr_name == "ascent") {
				top_limit = -double.parse (attr_content);
			}
			
			if (attr_name == "descent") {
				bottom_limit = -double.parse (attr_content);
			}		
		}
		
		top_limit *= units;
		bottom_limit *= units;
		
		font.bottom_limit = bottom_limit;
		font.top_limit = top_limit;
	}
	
	void parse_font_tag (Xml.Node* node) {
		string attr_name = "";
		string attr_content;
		
		for (Xml.Attr* prop = node->properties; prop != null; prop = prop->next) {
			attr_name = prop->name;
			attr_content = prop->children->content;
			
			if (attr_name == "horiz-adv-x") {
				font_advance = double.parse (attr_content);
			}
						
			if (attr_name == "id") {
				font.set_name (attr_content);
			}
		}
	}
	
	/** Obtain unichar value from either a character, a hex representation of
	 *  a character or series of characters (f, &#x6d; or ffi).
	 */
	static unichar get_unichar (string val) {
		string v = val;
		unichar unicode_value;
		
		if (val == "&") {
			return '&';
		}
		
		// TODO: parse ligatures
		if (v.has_prefix ("&")) {
			// parse hex value
			v = v.substring (0, v.index_of (";"));
			v = v.replace ("&#x", "U+");
			v = v.replace (";", "");
			unicode_value = Font.to_unichar (v);
		} else {
			// obtain unicode value
			
			if (v.char_count () > 1) {
				warning ("font contains ligatures");
				return '\0';
			}
			
			unicode_value = v.get_char (0);
		}
		
		return unicode_value;	
	}
	
	void parse_glyph (Xml.Node* node) {
		string attr_name = "";
		string attr_content;
		unichar unicode_value = 0;
		string glyph_name = "";
		string svg = "";
		Glyph glyph;
		double advance = font_advance;

		for (Xml.Attr* prop = node->properties; prop != null; prop = prop->next) {
			attr_name = prop->name;
			attr_content = prop->children->content;

			if (attr_name == "unicode") {
				unicode_value = get_unichar (attr_content);
				glyph_name = attr_content;
			}
			
			// svg data
			if (attr_name == "d") {
				svg = attr_content;
			}
			
			if (attr_name == "glyph-name") {
				// use glyph value as name until ligatures is properly implemented
				if (glyph_name == "") {
					glyph_name = attr_content;
				}
			}

			if (attr_name == "horiz-adv-x") {
				advance = double.parse (attr_content);
			}
		}
		
		// FIXME: this code will ignore characters that are mapped several glyphs
		if (unicode_value != '\0') {
			glyph = new Glyph (glyph_name, unicode_value);
			ImportSvg.parse_svg_data (svg, glyph, true, units);			
			glyph.right_limit = glyph.left_limit + advance * units;
			font.add_glyph_callback (glyph);
		} else {
			warning ("ignoring glyph");
		}
	}
}

}