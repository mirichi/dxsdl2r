require 'sdl2r'

SDL.init(SDL::INIT_EVERYTHING)
SDL::TTF.init

module DXRuby
  C_WHITE = [255, 255, 255]
  C_RED = [255, 0, 0]

  # DXRuby色配列からSDL::Color色配列へ変換
  def self._convert_color_dxruby_to_sdl(color)
    if color.size == 4
      color[1..3] << color[0]
    else
      color + [255]
    end
  end

  def self.convert_color_sdl_to_dxruby(color)
    color[3] + color[0..2]
  end
end

require_relative './dxsdl2r/rendertarget.rb'
require_relative './dxsdl2r/window.rb'
require_relative './dxsdl2r/image.rb'
require_relative './dxsdl2r/input.rb'
require_relative './dxsdl2r/sprite.rb'
require_relative './dxsdl2r/font.rb'

include DXRuby

END{
  SDL::TTF.quit
  SDL.quit
}
