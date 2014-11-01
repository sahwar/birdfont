/*
    Copyright (C) 2014 Johan Mattsson

    This library is free software; you can redistribute it and/or modify 
    it under the terms of the GNU Lesser General Public License as 
    published by the Free Software Foundation; either version 3 of the 
    License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful, but 
    WITHOUT ANY WARRANTY; without even the implied warranty of 
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU 
    Lesser General Public License for more details.
*/

using Cairo;

namespace BirdFont {

/** Testing class for an experimental implementation of a birdfont rendering engine. */
public class TextTab : FontDisplay {

	Text text_area;
	Text text_area2;
	Text text_area3;

	public TextTab () {	
		text_area = new Text ();
		text_area.load_font ("testfont.bf");
		text_area.set_text ("Test");

		text_area2 = new Text ();
		text_area2.load_font ("testfont.bf");
		text_area2.set_text ("Birdfont ÅÄÖ");

		text_area3 = new Text ();
		text_area3.load_font ("testfont.bf");
		text_area3.set_text ("TEST 3");
	}

	public override void draw (WidgetAllocation allocation, Context cr) {		
		text_area.draw (cr, 0, 0, 200, 200, 16);
		text_area2.draw (cr, 0, 100, 200, 200, 16);
		text_area3.draw (cr, 0, 200, 200, 200, 16);
	}	
}

}
