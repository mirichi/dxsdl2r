require 'sdl2r'

module DXRuby
  class Sprite
    def self.update(sprites)
      sprites.flatten.each do |s|
        if !s.respond_to?(:vanished?) or !s.vanished?
          if s.respond_to?(:update)
            s.update
          end
        end
      end
      nil
    end

    def self.draw(sprites)
      sprites.flatten.each do |s|
        if !s.respond_to?(:vanished?) or !s.vanished?
          if s.respond_to?(:draw)
            s.draw
          end
        end
      end
      nil
    end

    def self.clean(sprites)
      sprites.size.times do |i|
        s = sprites[i]
        if s.kind_of?(Array)
          Sprite.clean(s)
        else
          if s.respond_to?(:vanished?)
            sprites[i] = nil if s.vanished?
          end
        end
      end
      sprites.compact!
      nil
    end

    def x;@_x;end
    def x=(v);@_x=v;end
    def y;@_y;end
    def y=(v);@_y=v;end
    def z;@_z;end
    def z=(v);@_z=v;end
    def image;@_image;end
    def image=(v);@_image=v;end
    def target;@_target;end
    def target=(v);@_target=v;end
    def collision;@_collision;end
    def collision=(v);@_collision=v;end
    def vanished?;@_vanished;end
    def vanish;@_vanished=true;end

    def initialize(x=0, y=0, image=nil)
      @_x, @_y, @_image = x, y, image
      @_z = 0
      @_vanished = false
    end

    def draw
      if @_target
        @_target.draw(@_x, @_y, @_image, @_z)
      else
        Window.draw(@_x, @_y, @_image, @_z)
      end
      self
    end
  end
end
