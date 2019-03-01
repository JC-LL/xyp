class Array
  def x
    self[0]
  end

  def y
    self[1]
  end

  def x=(v)
    self[0]=v
  end

  def y=(v)
    self[1]=v
  end
end

module XYP

  Point= Struct.new(:x,:y) do
    def -(other)
      Point.new(self.x-other.x,self.y-other.y)
    end

    def +(other)
      Point.new(self.x+other.x,self.y+other.y)
    end

    def to_i
      Point.new(x.to_i,y.to_i)
    end

    def to_a
      [x,y]
    end
  end

  class View
    attr_accessor :center,:dims
    def initialize center,dims
      @center=center
      @dims=dims.map(&:to_f)
    end
  end

  class Plot

    attr_accessor :ratio
    attr_accessor :name,:data_set
    attr_accessor :moving

    def initialize name
      @name=name
    end

    def set_data_set hash
      @data_set=hash
    end

    def set_view view
      @view=view
    end

    def set_window_size size
      @window_size=size
    end

    def set_background_rgba color
      @color_rbga=color
    end

    def plot cairo
      wx,wy=*@window_size.map(&:to_f)
      vx,vy=*(@view.dims||[1,1]).map(&:to_f)
      @ratio=[wx/vx,wy/vy]
      cairo.set_source_rgba @color_rbga
      cairo.paint
      paint_grid(cairo)
      paint_axis(cairo)
      paint_data_set_line(cairo)
    end

    def window_coord p
      cx=@view.dims.x/2.0-@view.center.x
      cy=@view.dims.y/2.0-@view.center.y
      xx=(p.x+cx)*@ratio.x
      yy=@window_size.y-(p.y+cy)*@ratio.y
      Point.new xx,yy
    end

    def draw_line(ctx,start_,end_) # true abstract coord
      p1=window_coord(start_)
      ctx.move_to(p1.x,p1.y)
      p2=window_coord(end_)
      ctx.line_to(p2.x,p2.y)
      ctx.stroke
    end

    def draw_point ctx,center,radius # true abstract coord
      p=window_coord(center)
      ctx.arc p.x,p.y,1,0,2*Math::PI
      ctx.fill
    end

    def paint_data_set_line ctx
      ctx.set_source *YELLOW
      @points||=@data_set.each.collect{|a,b| Point.new(a,b)}
      @points.each_cons(2) do |start,end_|
        draw_line(ctx,start,end_)
      end
    end

    def paint_grid ctx
      x_1=(@view.center.x-@view.dims.x/2-2).to_i
      x_2=(@view.center.x+@view.dims.x/2+2).to_i
      y_1=(@view.center.y-@view.dims.y/2).to_i
      y_2=(@view.center.y+@view.dims.y/2).to_i
      x_range=x_1..x_2
      y_range=y_1..y_2
      transparency=400.0/(x_range.size*y_range.size)
      if transparency>0.08
        for x in x_range
          for y in y_range
            ctx.set_source ORANGE.red,ORANGE.green,ORANGE.blue,transparency
            center=Point.new(x,y)
            draw_point(ctx,center,1)
          end
        end
      end
    end

    def paint_text_axis ctx,txt,point,axis_sym
      coord=*window_coord(point).to_a
      coord.x+=20 if axis_sym==:y
      coord.y-=20 if axis_sym==:x
      ctx.move_to *coord
      ctx.show_text txt
    end

    def paint_axis ctx
      ctx.select_font_face "Monospace"
      ctx.set_font_size 13

      x_1=(@view.center.x-@view.dims.x/2)
      x_2=(@view.center.x+@view.dims.x/2)
      x_1-=1
      x_2+=1
      y  = 0
      p1=Point.new(x_1,y)
      p2=Point.new(x_2,y)
      ctx.set_source *ORANGE
      draw_line(ctx,p1,p2)

      size_tick=@view.dims.y.to_f/60
      range=x_1.to_i..x_2.to_i
      transparency=10.0/range.size
      if transparency>0.2
        for x in range
          p1=Point.new(x,-size_tick/2)
          p2=Point.new(x,size_tick/2)
          draw_line(ctx,p1,p2)
          paint_text_axis(ctx,"#{x}",p1,:x)
        end
      end


      y_1=(@view.center.y-@view.dims.y/2)
      y_2=(@view.center.y+@view.dims.y/2)
      x  = 0
      y_1-=3
      y_2+=3
      p3=Point.new(x,y_1)
      p4=Point.new(x,y_2)
      ctx.set_source *ORANGE
      draw_line(ctx,p3,p4)

      size_tick=@view.dims.x.to_f/80
      range=y_1.to_i..y_2.to_i
      transparency=10.0/range.size

      if transparency>0.2
        for y in range
          ctx.set_source ORANGE.red,ORANGE.green,ORANGE.blue,transparency
          p1=Point.new(-size_tick/2,y)
          p2=Point.new(size_tick/2,y)
          draw_line(ctx,p1,p2)
          paint_text_axis(ctx,"#{y}",p1,:y)
        end
      end
    end
  end
end
