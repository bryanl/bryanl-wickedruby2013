#!/usr/bin/env ruby

class Points
  def initialize(points)
    @points = points
  end

  def center
    x_points = points.map(&:x)
    y_points = points.map(&:y)

    x = (x_points.max - x_points.min)/2.0
    y = (y_points.max - y_points.min)/2.0
    Point.new(x,y)
  end
end

def Point
  attr_accessor :x, :y

  def initialize(x,y)
    @x=x
    @y=y
  end
end