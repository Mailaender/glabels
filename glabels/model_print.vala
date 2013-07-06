/*  model_print.vala
 *
 *  Copyright (C) 2011-2012  Jim Evins <evins@snaught.com>
 *
 *  This file is part of gLabels.
 *
 *  gLabels is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  gLabels is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with gLabels.  If not, see <http://www.gnu.org/licenses/>.
 */


using GLib;
using libglabels;

namespace glabels
{

	public class ModelPrint
	{

		private const double OUTLINE_WIDTH =  0.25;
		private const double TICK_OFFSET   =  2.25;
		private const double TICK_LENGTH   = 18.0;


		public signal void changed();


		private Label label;


		/**
		 * Simple N Sheets
		 */
		public int simple_n_sheets
		{
			get { return _simple_n_sheets; }

			set
			{
				if ( _simple_n_sheets != value )
				{
					_simple_n_sheets = value;
					changed();
				}
			}
		}
		private int _simple_n_sheets;


		/**
		 * Simple Start
		 */
		public int simple_start
		{
			get { return _simple_start; }

			set
			{
				if ( _simple_start != value )
				{
					_simple_start = value;
					changed();
				}
			}
		}
		private int _simple_start;


		/**
		 * Simple End
		 */
		public int simple_end
		{
			get { return _simple_end; }

			set
			{
				if ( _simple_end != value )
				{
					_simple_end = value;
					changed();
				}
			}
		}
		private int _simple_end;


		/**
		 * Print Outline Flag
		 */
		public bool outline_flag
		{
			get { return _outline_flag; }

			set
			{
				if ( _outline_flag != value )
				{
					_outline_flag = value;
					changed();
				}
			}
		}
		private bool _outline_flag;

		/**
		 * Print in Reverse Flag
		 */
		public bool reverse_flag
		{
			get { return _reverse_flag; }

			set
			{
				if ( _reverse_flag != value )
				{
					_reverse_flag = value;
					changed();
				}
			}
		}
		private bool _reverse_flag;

		/**
		 * Print Crop Marks Flag
		 */
		public bool crop_marks_flag
		{
			get { return _crop_marks_flag; }

			set
			{
				if ( _crop_marks_flag != value )
				{
					_crop_marks_flag = value;
					changed();
				}
			}
		}
		private bool _crop_marks_flag;

		public int   n_pages         { get; set; }


		private Gee.ArrayList<MergeRecord> record_list;


		public ModelPrint( Label label )
		{
			this.label = label;

			on_merge_changed();

			label.merge_changed.connect( on_merge_changed );
		}


		private void on_merge_changed()
		{
			on_merge_selection_changed();

			label.merge.source_changed.connect( on_merge_selection_changed );
			label.merge.selection_changed.connect( on_merge_selection_changed );
		}


		private void on_merge_selection_changed()
		{
			record_list = label.merge.get_selected_records();

			if ( label.merge is MergeNone )
			{
				n_pages = 1;
			}
			else
			{
				TemplateFrame frame = label.template.frames.first().data;
				n_pages = record_list.size / frame.get_n_labels();
				if ( (record_list.size % frame.get_n_labels()) != 0 )
				{
					n_pages++;
				}

				if ( n_pages == 0 )
				{
					n_pages = 1;
				}
			}
		}


		public void print_sheet( Cairo.Context cr, int i_page )
		{
			if ( label.merge is MergeNone )
			{
				print_simple_sheet( cr, i_page );
			}
			else
			{
				print_merge_sheet( cr, i_page );
			}
		}


		private void print_simple_sheet( Cairo.Context cr, int i_page )
		{
			if ( crop_marks_flag )
			{
				print_crop_marks( cr );
			}

			TemplateFrame frame = label.template.frames.first().data;
			Gee.ArrayList<TemplateCoord?> origins = frame.get_origins();

			foreach ( TemplateCoord origin in origins )
			{
				print_label( cr, origin.x, origin.y, null );
			}
		}


		private void print_merge_sheet( Cairo.Context cr, int i_page )
		{
			if ( crop_marks_flag )
			{
				print_crop_marks( cr );
			}

			TemplateFrame frame = label.template.frames.first().data;
			Gee.ArrayList<TemplateCoord?> origins = frame.get_origins();

			int i = i_page * frame.get_n_labels();

			foreach ( TemplateCoord origin in origins )
			{
				if ( i >= record_list.size )
				{
					break;
				}

				print_label( cr, origin.x, origin.y, record_list.get(i) );

				i++;
			}
		}


		private void print_crop_marks( Cairo.Context cr )
		{
			TemplateFrame frame = label.template.frames.first().data;

			double w, h;
			frame.get_size( out w, out h );

			cr.save();

			cr.set_source_rgb( 0, 0, 0 );
			cr.set_line_width( OUTLINE_WIDTH );

			foreach ( TemplateLayout layout in frame.layouts )
			{

				double xmin = layout.x0;
				double ymin = layout.y0;
				double xmax = layout.x0 + layout.dx*(layout.nx - 1) + w;
				double ymax = layout.y0 + layout.dy*(layout.ny - 1) + h;

				for ( int ix=0; ix < layout.nx; ix++ )
				{
					double x1 = xmin + ix*layout.dx;
					double x2 = x1 + w;

					double y1 = double.max((ymin - TICK_OFFSET), 0.0);
					double y2 = double.max((y1 - TICK_LENGTH), 0.0);

					double y3 = double.min((ymax + TICK_OFFSET), label.template.page_height);
					double y4 = double.min((y3 + TICK_LENGTH), label.template.page_height);

					cr.move_to( x1, y1 );
					cr.line_to( x1, y2 );
					cr.stroke();

					cr.move_to( x2, y1 );
					cr.line_to( x2, y2 );
					cr.stroke();

					cr.move_to( x1, y3 );
					cr.line_to( x1, y4 );
					cr.stroke();

					cr.move_to( x2, y3 );
					cr.line_to( x2, y4 );
					cr.stroke();
				}

				for (int iy=0; iy < layout.ny; iy++ )
				{
					double y1 = ymin + iy*layout.dy;
					double y2 = y1 + h;

					double x1 = double.max((xmin - TICK_OFFSET), 0.0);
					double x2 = double.max((x1 - TICK_LENGTH), 0.0);

					double x3 = double.min((xmax + TICK_OFFSET), label.template.page_width);
					double x4 = double.min((x3 + TICK_LENGTH), label.template.page_width);

					cr.move_to( x1, y1 );
					cr.line_to( x2, y1 );
					cr.stroke();

					cr.move_to( x1, y2 );
					cr.line_to( x2, y2 );
					cr.stroke();

					cr.move_to( x3, y1 );
					cr.line_to( x4, y1 );
					cr.stroke();

					cr.move_to( x3, y2 );
					cr.line_to( x4, y2 );
					cr.stroke();
				}

			}

			cr.restore();
		}


		private void print_label( Cairo.Context cr,
		                          double        x,
		                          double        y,
		                          MergeRecord?  record )
		{
			double w, h;
			label.get_size( out w, out h );

			cr.save();

			/* Transform coordinate system to be relative to upper corner */
			/* of the current label */
			cr.translate( x, y );

			cr.save();

			clip_to_outline( cr );

			cr.save();

			/* Special transformations. */
			if ( label.rotate )
			{
				cr.rotate( Math.PI/2 );
				cr.translate( 0, -h );
			}
			if ( reverse_flag )
			{
				cr.translate( w, 0 );
				cr.scale( -1, 1 );
			}

			label.draw( cr, false, record );

			cr.restore(); /* From special transformations. */

			cr.restore(); /* From clip to outline. */

			if ( outline_flag )
			{
				draw_outline( cr );
			}

			cr.restore(); /* From translation. */
		}


		private void draw_outline( Cairo.Context cr )
		{
			cr.save();

			cr.set_source_rgb( 0, 0, 0 );
			cr.set_line_width( OUTLINE_WIDTH );

			TemplateFrame frame = label.template.frames.first().data;
			frame.cairo_path( cr, false );

			cr.stroke();

			cr.restore();
		}


		private void clip_to_outline( Cairo.Context cr )
		{
			TemplateFrame frame = label.template.frames.first().data;
			frame.cairo_path( cr, true );

			cr.set_fill_rule( Cairo.FillRule.EVEN_ODD );
			cr.clip();
		}


	}

}