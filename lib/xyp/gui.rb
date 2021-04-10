require 'gtk3'

require_relative 'plot'

GREY    = Gdk::RGBA::new(0.2, 0.2, 0.2, 1)
RED     = Cairo::Color.parse("red")
CYAN    = Cairo::Color.parse("cyan")
YELLOW  = Cairo::Color.parse("yellow")
GREEN   = Cairo::Color.parse("green")
ORANGE  = Cairo::Color.parse("orange")

SINUS = (-10*Math::PI..10*Math::PI).step(0.1).inject({}){|hash,x| hash[x]=Math::sin(x) ; hash}

module XYP

  class GUI

    def initialize
      glade_file = File.expand_path(__dir__)+"/gui_v0.glade"
      builder=Gtk::Builder.new
      builder.add_from_file(glade_file)
      builder.connect_signals{|handler| method(handler)}
      @main_window = builder['window1']
      @main_window.signal_connect("destroy"){Gtk.main_quit}

      @drawing =builder['drawingarea1']

      @drawing.add_events [:leave_notify_mask,
                           :button_press_mask,
                           :pointer_motion_mask,
                           :pointer_motion_hint_mask]
      create_callbacks
      dummy_test
    end

    def create_callbacks
      @drawing.signal_connect("draw"){redraw}

      @drawing.signal_connect("button-press-event") do |widget, event|
        @start_drag=Point.new(event.x,event.y)
  		end

      @drawing.signal_connect("motion-notify-event") do |widget, event|
        do_it=false
        if @start_drag
           modify_center event
           @start_drag=@end_drag
           redraw
        end
  		end

      @drawing.signal_connect("button-release-event") do |widget, event|
        modify_center event
        @start_drag=nil
        redraw
  		end
    end

    def modify_center event
      @end_drag=Point.new(event.x,event.y)
      delta_x=((@end_drag.x-@start_drag.x)/@plot.ratio.x)
      delta_y=((@end_drag.y-@start_drag.y)/@plot.ratio.y)
      delta=Point.new(delta_x,-delta_y)
      @view.center=@view.center-delta
    end

    def run options
      @main_window.show
      if filename=options[:data_file]
        load_data(filename)
      end
      Gtk.main
    end

    # signal handler for main window destory event
    def quit
      Gtk.main_quit
    end

    def on_button_info_clicked
      about = Gtk::AboutDialog.new
      about.set_program_name "xyp"
      about.set_version "0.0.1"
      about.set_copyright "(c) Jean-Christophe Le Lann"
      about.set_comments "Ruby GTK3 XY Plotter"
      about.set_website "http://www.jcll.fr"
      begin
        dir = File.expand_path(__dir__)
        logo = GdkPixbuf::Pixbuf.new :file => "#{dir}/../../doc/screen.png"
        about.set_logo logo
      rescue IOError => e
          puts e
          puts "cannot load image"
          exit
      end
      about.run
      about.destroy
    end

    def on_filechooserbutton1_file_set chooser
      load_data(chooser.filename)
    end

    def load_data filename
      @dataset=IO.readlines(filename).inject({}) do |hash,line|
        x,y=*line.split.map(&:to_f)
        hash[x]=y
        hash
      end

      @plot=Plot.new(filename)
      @plot.set_background_rgba GREY
      @plot.set_data_set @dataset
      on_button_zoom_fit_clicked
    end

    def on_button_zoom_fit_clicked
      if @dataset
        min_x,max_x=@dataset.keys.minmax
        min_y,max_y=@dataset.values.minmax
    
        center_x=min_x+(max_x-min_x).abs/2
        center_y=min_y+(max_y-min_y).abs/2
        center=Point.new(center_x,center_y)

        diff_x=max_x-min_x
        diff_y=max_y-min_y
        dims=[diff_x,diff_y]

        @view=View.new(center,dims)

        @plot.set_view @view
        redraw
      end
    end

    def on_button_zoom_x_clicked
      @view.dims.x/=2
      redraw
    end

    def on_button_unzoom_x_clicked
      @view.dims.x*=2
      redraw
    end

    def on_button_zoom_y_clicked
      @view.dims.y/=2
      redraw
    end

    def on_button_unzoom_y_clicked
      @view.dims.y*=2
      redraw
    end

    #===============================================================

    def handle_window_redimensioning
      width,height=@drawing.window.width,@drawing.window.height
      @plot.set_window_size [width,height]
    end

    def redraw
      handle_window_redimensioning
      cr = @drawing.window.create_cairo_context
      @plot.plot(cr)
    end

    #===============================================================
    def dummy_test
      @plot=Plot.new(:test)
      @plot.set_background_rgba GREY
      @plot.set_data_set @dataset=SINUS
      center_1_1=Point.new(1,1)
      @view=View.new(center_1_1,[60,4])
      @plot.set_view @view
      # plot is done during redraw
    end
  end
end
