require 'sdl2r'

module DXRuby
  class Image
    attr_accessor :_surface, :_texture, :_pixels

    def self.load(filename)
      image = Image.new(0, 0)
      image._surface = SDL::IMG.load(filename)
      image._pixels = image._surface.pixels
      image
    end

    def self.load_tiles(filename, cx, cy)
      surface = SDL::IMG.load(filename)
      w, h = surface.w, surface.h
      ary = []
      cy.times do |y|
        cx.times do |x|
          tmp = Image.new(0, 0)
          # IntelCPUはリトルエンディアンだがビッグエンディアンにも一応対応しておく
          # 画像フォーマットは32bit固定
          if SDL::BYTEORDER == SDL::BIG_ENDIAN
            tmp._surface = SDL.create_rgb_surface(0, w / cx, h / cy, 32, 0xff000000, 0x00ff0000, 0x0000ff00, 0x000000ff)
          else
            tmp._surface = SDL.create_rgb_surface(0, w / cx, h / cy, 32, 0x000000ff, 0x0000ff00, 0x00ff0000, 0xff000000)
          end
          SDL.blit_surface(surface, SDL::Rect.new(w / cx * x, h / cy * y, w / cx, h / cy), tmp._surface, nil)
          tmp._pixels = tmp._surface.pixels
          ary << tmp
        end
      end
      ary
    end

    def initialize(w, h, color=[0, 0, 0, 0])
      # wとhの両方が0の場合はSurfaceを生成しない
      return if w == 0 and h == 0

      # IntelCPUはリトルエンディアンだがビッグエンディアンにも一応対応しておく
      # 画像フォーマットは32bit固定
      if SDL::BYTEORDER == SDL::BIG_ENDIAN
        @_surface = SDL.create_rgb_surface(0, w, h, 32, 0xff000000, 0x00ff0000, 0x0000ff00, 0x000000ff)
      else
        @_surface = SDL.create_rgb_surface(0, w, h, 32, 0x000000ff, 0x0000ff00, 0x00ff0000, 0xff000000)
      end

      # 指定色で塗りつぶす
      SDL.fill_rect(@_surface, nil, DXRuby._convert_color_dxruby_to_sdl(color))

      # Pixelsオブジェクト取得
      @_pixels = @_surface.pixels
    end

    def width
      @_surface.w
    end

    def height
      @_surface.h
    end

    # テクスチャを破棄する
    # 次に描画で使われる際に再生成される
    def _modify
      if @_texture
        SDL.destroy_texture(@_texture)
        @_texture = nil
      end
      nil
    end

    # テクスチャ生成
    def _create_texture
      # テクスチャ生成
      @_texture = SDL.create_texture_from_surface(Window._renderer, @_surface)
    end

    # ピクセルに色を置く
    def []=(x, y, color)
      begin
        @_pixels[x, y] = DXRuby._convert_color_dxruby_to_sdl(color)
        self._modify
      rescue SDL::SDL2RError
        # 範囲外指定の場合に出るエラーは無視する
      end
      color
    end

    # ピクセルの色を取得する
    def [](x, y)
      DXRuby._convert_color_sdl_to_dxruby(@_pixels[x, y])
    end

    # 円を描画する
    def circle(x, y, r, color)
      xm = x
      ym = y
      diameter = r * 2
      col = DXRuby._convert_color_dxruby_to_sdl(color)

      cx = 0
      cy = diameter / 2 + 1
      d = -diameter * diameter + 4 * cy * cy -4 * cy + 2
      dx = 4
      dy = -8 * cy + 8
      if (diameter & 1) == 0
        xm -= 1
        ym -= 1
      end

      cx = 0
      while cx <= cy do
        if d > 0 
            d += dy
            dy += 8
            cy -= 1
        end

        self[ - cy + x, - cx + y ] = col
        self[ - cx + x, - cy + y ] = col

        self[ + cx + xm, - cy + y ] = col
        self[ + cy + xm, - cx + y ] = col

        self[ + cy + xm, + cx + ym ] = col
        self[ + cx + xm, + cy + ym ] = col

        self[ - cx + x, + cy + ym ] = col
        self[ - cy + x, + cx + ym ] = col

        d += dx
        dx += 8
        cx += 1
      end
      self._modify
      self
    end
  end
end
