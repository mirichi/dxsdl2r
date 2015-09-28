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

    def _auto_update
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
      self._set_pixel(x, y, DXRuby._convert_color_dxruby_to_sdl(color))
      self._modify
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

        self._set_pixel(- cy + x, - cx + y, col)
        self._set_pixel( - cx + x, - cy + y, col)

        self._set_pixel( + cx + xm, - cy + y, col)
        self._set_pixel( + cy + xm, - cx + y, col)

        self._set_pixel( + cy + xm, + cx + ym, col)
        self._set_pixel( + cx + xm, + cy + ym, col)

        self._set_pixel( - cx + x, + cy + ym, col)
        self._set_pixel( - cy + x, + cx + ym, col)

        d += dx
        dx += 8
        cx += 1
      end
      self._modify
      self
    end

    # 塗りつぶした円を描画する
    def circle_fill(x, y, r, color)
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

        self._hline(x - cy, xm + cy, y - cx, col)
        self._hline(x - cx, xm + cx, y - cy, col)
        self._hline(x - cy, xm + cy, ym + cx, col)
        self._hline(x - cx, xm + cx, ym + cy, col)

        d += dx
        dx += 8
        cx += 1
      end
      self._modify
      self
    end

    # 線を描画する
    def line(x1, y1, x2, y2, color)
      dx = x2 > x1 ? x2 - x1 : x1 - x2
      dy = y2 > y1 ? y2 - y1 : y1 - y2
      col = DXRuby._convert_color_dxruby_to_sdl(color)

      # ブレゼンハムアルゴリズムによる線分描画
      if dx < dy
        xp = x1 < x2 ? 1 : -1
        d = y1 < y2 ? 1 : -1
        c = dy
        i = 0
        while i <= dy do
          self._set_pixel(x1, y1, col)
          y1 = y1 + d
          c = c + dx*2
          if c >= dy*2
            c = c - dy*2
            x1 = x1 + xp
          end
          i += 1
        end
      else
        yp = y1 < y2 ? 1 : -1
        d = x1 < x2 ? 1 : -1
        c = dx
        i = 0
        while i <= dx do
          self._set_pixel(x1, y1, col)
          x1 = x1 + d
          c = c + dy*2
          if c >= dx*2
            c = c - dx*2
            y1 = y1 + yp
          end
          i += 1
        end
      end
      self._modify
      self
    end

    # 四角を描画する
    def box(x1, y1, x2, y2, color)
      col = DXRuby._convert_color_dxruby_to_sdl(color)
      self._hline(x1, x2, y1, col)
      self._vline(x2, y1, y2, col)
      self._vline(x1, y1, y2, col)
      self._hline(x1, x2, y2, col)
      self._modify
      self
    end

    # 塗りつぶした四角を描画する
    def box_fill(x1, y1, x2, y2, color)
      col = DXRuby._convert_color_dxruby_to_sdl(color)

      if x1 > x2
        tmp = x1
        x1 = x2
        x2 = tmp
      end
      if y1 > y2
        tmp = y1
        y1 = y2
        y2 = tmp
      end

      SDL.fill_rect(@_surface, SDL::Rect.new(x1, y1, x2 - x1 + 1, y2 - y1 + 1), col)

      self._modify
      self
    end

    # 全体を塗りつぶす
    def clear(color=[0, 0, 0, 0])
      col = DXRuby._convert_color_dxruby_to_sdl(color)
      SDL.fill_rect(@_surface, nil, col)
      self._modify
      self
    end

    # 内部用点描画
    def _set_pixel(x, y, color)
      begin
        @_pixels[x, y] = color
      rescue SDL::SDL2RError
        # 範囲外指定の場合に出るエラーは無視する
      end
    end

    # 内部処理用水平ライン描画
    # x1<=x2であること。colはsdl2rの色配列であること
    def _hline(x1, x2, y, col)
      x = x1
      while x <= x2
        self._set_pixel(x, y, col)
        x += 1
      end
    end

    # 内部処理用垂直ライン描画
    # y1<=y2であること。colはsdl2rの色配列であること
    def _vline(x, y1, y2, col)
      y = y1
      while y <= y2
        self._set_pixel(x, y, col)
        y += 1
      end
    end
  end
end
