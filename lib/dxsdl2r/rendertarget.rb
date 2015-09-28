require 'sdl2r'

module DXRuby
  class RenderTarget
    attr_accessor :_texture

    def initialize(w, h, bgcolor=[0, 0, 0, 0])
      @_reservation = []
      @_bgcolor = DXRuby._convert_color_dxruby_to_sdl(bgcolor)
      return if w == 0 and h == 0
      @_texture = SDL.create_texture(Window._renderer, SDL::PIXELFORMAT_RGBA8888, SDL::TEXTUREACCESS_TARGET, w, h)
    end

    def draw_box_fill(x1, y1, x2, y2, color, z=0)
      tmp = DXRuby._convert_color_dxruby_to_sdl(color)
      prc = ->{
        SDL.set_render_draw_blend_mode(Window._renderer, SDL::BLENDMODE_BLEND)
        SDL.set_render_draw_color(Window._renderer, *tmp)
        SDL.render_fill_rect(Window._renderer, SDL::Rect.new(x1, y1, x2 - x1 + 1, y2 - y1 + 1))
      }
      @_reservation << [z, prc]
    end

    def draw(x, y, image, z=0)
      prc = ->{
        image._create_texture unless image._texture
        SDL.set_texture_blend_mode(image._texture, SDL::BLENDMODE_BLEND)
        SDL.render_copy(Window._renderer, image._texture, nil, SDL::Rect.new(x, y, image.width, image.height))
      }
      @_reservation << [z, prc]
    end

    def draw_ex(x, y, image, option={})
      option = {
        angle: 0,
        scale_x: 1,
        scale_y: 1,
        center_x: 0,
        center_y: 0,
        z: 0,
      }.merge(option)
      prc = ->{
        SDL::render_copy_ex(Window._renderer, image._texture, nil, SDL::Rect.new(x, y, image.width, image.height), option[:angle], nil, 0)
      }
      @_reservation << [option[:z], prc]
    end

    def draw_font(x, y, str, font, hash = {})
      option = {
        color: [255, 255, 255, 255],
        z: 0,
      }.merge(hash)
      sur = SDL::TTF.render_utf8_blended(font._font, str, DXRuby._convert_color_dxruby_to_sdl(option[:color]))
      tex = SDL.create_texture_from_surface(Window._renderer, sur)
      SDL.free_surface(sur)
      _, _, w, h = SDL.query_texture(tex)

      prc = ->{
        SDL.set_texture_blend_mode(tex, SDL::BLENDMODE_BLEND)
        SDL.render_copy(Window._renderer, tex, nil, SDL::Rect.new(x, y, w, h))
      }
      @_reservation << [option[:z], prc]
    end

    def clear
      SDL.set_render_target(Window._renderer, @_texture)
      SDL.set_render_draw_color(Window._renderer, *@_bgcolor)
      SDL.set_render_draw_blend_mode(Window._renderer, SDL::BLENDMODE_NONE)
      SDL.render_fill_rect(Window._renderer, nil)
    end

    def update
      self.clear
      @_reservation.sort_by!{|v|v[0]}.each{|v|v[1].call}
      @_reservation.clear
    end

    def width
      SDL.query_texture(@_texture)[2]
    end

    def height
      SDL.query_texture(@_texture)[3]
    end

    def bgcolor
      DXRuby._convert_color_sdl_to_dxruby(@_bgcolor)
    end

    def bgcolor=(bgcolor)
      @_bgcolor = DXRuby._convert_color_dxruby_to_sdl(bgcolor)
    end
  end
end
