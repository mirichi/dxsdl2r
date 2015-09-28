require 'sdl2r'
require_relative 'fpstimer'

module DXRuby
  module Window
    @_width = 640
    @_height = 480
    @_window = SDL.create_window("dxsdl2r Sample Application",
                                  SDL::WINDOWPOS_UNDEFINED,
                                  SDL::WINDOWPOS_UNDEFINED,
                                  @_width,
                                  @_height,
                                  SDL::WINDOW_HIDDEN)
    @_renderer = SDL.create_renderer(@_window, -1, 0)
    @_render_target = RenderTarget.new(0, 0, [0, 0, 0])

    # 描画予約配列
    @_reservation = []

    def self.width;@_width;end
    def self.height;@_height;end
    def self._window;@_window;end
    def self._renderer;@_renderer;end
    def self.width=(v);@_width=v;end
    def self.height=(v);@_height=v;end

    def self.draw_box_fill(x1, y1, x2, y2, color, z=0)
      @_render_target.draw(x1, y1, x2, y2, color, z)
    end

    def self.draw(x, y, image, z=0)
      @_render_target.draw(x, y, image, z)
    end

    def self.draw_ex(x, y, image, option={})
      @_render_target.draw_ex(x, y, image, option)
    end

    def self.draw_font(x, y, str, font, hash = {})
      @_render_target.draw_font(x, y, str, font, hash)
    end

    def self.loop
      timer = FPSTimer.instance
      timer.reset
      SDL.set_window_size(@_window, @_width, @_height)
      SDL.show_window(@_window)
      Kernel.loop do
        timer.wait_frame do
          return if Input.update

          yield

          @_render_target.update
          RenderTarget._render_targets.each do |r|
            r._update_flg = true
          end
          RenderTarget._render_targets.clear
          SDL.render_present(@_renderer)
        end
      end
    end

    def self.fps=(v)
      FPSTimer.instance.fps = v
    end

    def self.real_fps
      FPSTimer.instance.real_fps
    end

    def self.caption
      SDL.get_window_title(@_window)
    end

    def self.caption=(str)
      SDL.set_window_title(@_window, str)
      str
    end

    def bgcolor
      @_render_target.bgcolor
    end

    def bgcolor=(bgcolor)
      @_render_target.bgcolor = bgcolor
    end
  end
end
