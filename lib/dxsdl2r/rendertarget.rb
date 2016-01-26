require 'sdl2r'

module DXRuby
  class RenderTarget
    attr_accessor :_texture, :_framebuffer, :_reservation, :_update_flg, :_displaylist_number

    @@_render_targets = []
    def self._render_targets
      @@_render_targets
    end

    def self._create_displaylist
      @@displaylist = glGenLists(2)

      # 通常の描画用
      glNewList(@@displaylist+1, GL_COMPILE)
      glBegin(GL_TRIANGLES)
      glTexCoord2d(0.0, 1.0)
      glVertex2f(-0.5, -0.5)
      glTexCoord2d(1.0, 1.0)
      glVertex2f(0.5, -0.5)
      glTexCoord2d(0.0, 0.0)
      glVertex2f(-0.5, 0.5)
      glTexCoord2d(0.0, 0.0)
      glVertex2f(-0.5, 0.5)
      glTexCoord2d(1.0, 1.0)
      glVertex2f(0.5, -0.5)
      glTexCoord2d(1.0, 0.0)
      glVertex2f(0.5, 0.5)
      glEnd()
      glEndList()

      # RenderTargetテクスチャの描画用
      glNewList(@@displaylist, GL_COMPILE)
      glBegin(GL_TRIANGLES)
      glTexCoord2d(0.0, 0.0)
      glVertex2f(-0.5, -0.5)
      glTexCoord2d(1.0, 0.0)
      glVertex2f(0.5, -0.5)
      glTexCoord2d(0.0, 1.0)
      glVertex2f(-0.5, 0.5)
      glTexCoord2d(0.0, 1.0)
      glVertex2f(-0.5, 0.5)
      glTexCoord2d(1.0, 0.0)
      glVertex2f(0.5, -0.5)
      glTexCoord2d(1.0, 1.0)
      glVertex2f(0.5, 0.5)
      glEnd()
      glEndList()
    end

    def initialize(w, h, bgcolor=[0, 0, 0, 0])
      @_reservation = []
      @_bgcolor = DXRuby._convert_color_dxruby_to_sdl(bgcolor)
      @_framebuffer = 0
      @_displaylist_number = 1
      return if w == 0 and h == 0

      @_texture = Image._create_gl_texture(w, h)

      @_framebuffer = glGenFramebuffer()
      glBindFramebuffer(GL_FRAMEBUFFER, @_framebuffer)
      glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, @_texture, 0)
      glBindFramebuffer(GL_FRAMEBUFFER, 0)

      @_width = w
      @_height = h

      @_update_flg = false
    end

    # def draw_box_fill(x1, y1, x2, y2, color, z=0)
    #   tmp = DXRuby._convert_color_dxruby_to_sdl(color)
    #   prc = ->{
    #     SDL.set_render_draw_blend_mode(Window._renderer, SDL::BLENDMODE_BLEND)
    #     SDL.set_render_draw_color(Window._renderer, *tmp)
    #     SDL.render_fill_rect(Window._renderer, SDL::Rect.new(x1, y1, x2 - x1 + 1, y2 - y1 + 1))
    #   }
    #   @_reservation << [z, prc]
    # end

    def _auto_update
      if @_reservation.empty?
        if @_update_flg
          self.clear
        end
      else
        self.update
      end
      @@_render_targets << self
    end

    def draw(x, y, image, z=0)
      image._auto_update
      prc = ->{
        image._create_texture unless image._texture
        w = image.width
        h = image.height

        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
        glEnable(GL_BLEND)
        glBindTexture(GL_TEXTURE_2D, image._texture)

        glPushMatrix()

        glTranslatef(w / 2.0 + x, h / 2.0 + y, 0)
        glScalef(w, h, 0)

        glCallList(@@displaylist + image._displaylist_number)

        glPopMatrix()
      }
      @_reservation << [z, prc]
    end

    def draw_shader(x, y, image, shader, z=0)
      image._auto_update
      prc = ->{
        image._create_texture unless image._texture
        w = image.width
        h = image.height

        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
        glEnable(GL_BLEND)
        glBindTexture(GL_TEXTURE_2D, image._texture)

        glUseProgram(shader.core.program)

        glUniform1i(glGetUniformLocation(shader.core.program, "sampler"), 0)
        shader._set_uniform

        glPushMatrix()

        glTranslatef(w / 2.0 + x, h / 2.0 + y, 0)
        glScalef(w, h, 0)

        glCallList(@@displaylist + image._displaylist_number)

        glPopMatrix()
        glUseProgram(0)
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
      image._auto_update
      prc = ->{
        image._create_texture unless image._texture
        w = image.width
        h = image.height

        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
        glEnable(GL_BLEND)
        glBindTexture(GL_TEXTURE_2D, image._texture)

        glPushMatrix()

        glTranslatef(w / 2.0 + x, h / 2.0 + y, 0)
        glRotatef(option[:angle], 0, 0, 1)
        glScalef(w * option[:scale_x], h * option[:scale_y], 0)

        glCallList(@@displaylist + image._displaylist_number)

        glPopMatrix()
      }
      @_reservation << [option[:z], prc]
    end

    def draw_font(x, y, str, font, hash = {})
      option = {
        color: [255, 255, 255, 255],
        z: 0,
      }.merge(hash)
      tmp = SDL::TTF.render_utf8_blended(font._font, str, DXRuby._convert_color_dxruby_to_sdl(option[:color]))
      sur = Image._convert_rgba_surface(tmp)
      w, h = sur.w, sur.h
      tex = Image._create_gl_texture(w, h, sur)
      SDL.free_surface(sur)
      SDL.free_surface(tmp)

      prc = ->{
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
        glEnable(GL_BLEND)
        glBindTexture(GL_TEXTURE_2D, tex)

        glPushMatrix()

        glTranslatef(w / 2.0 + x, h / 2.0 + y, 0)
        glScalef(w, h, 0)

        glCallList(@@displaylist + image._displaylist_number)

        glPopMatrix()
      }
      @_reservation << [option[:z], prc]
    end

    def clear
      glBindFramebuffer(GL_FRAMEBUFFER, @_framebuffer)
      glClearColor(@_bgcolor[0] / 255.0, @_bgcolor[1] / 255.0, @_bgcolor[2] / 255.0, @_bgcolor[3] / 255.0)
      glClear(GL_COLOR_BUFFER_BIT)
      @_update_flg = false
    end

    def update
      self.clear

      glDisable(GL_CULL_FACE)

      if @_framebuffer == 0
        glViewport( 0, 0, Window.width, Window.height )
      else
        glViewport( 0, 0, @_width, @_height )
      end
      glMatrixMode( GL_PROJECTION )
      glLoadIdentity( )
      if @_framebuffer == 0
        glOrtho(0, Window.width, Window.height, 0, -1.0, 1.0)
      else
        glOrtho(0, @_width, 0, @_height, -1.0, 1.0)
      end
      glMatrixMode( GL_MODELVIEW )
      glLoadIdentity( )

      glEnable(GL_TEXTURE_2D)
      glColor4f(1,1,1,1)

      @_reservation.sort_by!{|v|v[0]}.each{|v|v[1].call}
      @_reservation.clear

      glBindTexture(GL_TEXTURE_2D, 0)
      glDisable(GL_TEXTURE_2D)
    end

    def width
      @_width
    end

    def height
      @_height
    end

    def bgcolor
      DXRuby._convert_color_sdl_to_dxruby(@_bgcolor)
    end

    def bgcolor=(bgcolor)
      @_bgcolor = DXRuby._convert_color_dxruby_to_sdl(bgcolor)
    end
  end





  class RenderTarget3D < RenderTarget
    attr_accessor :_texture, :_framebuffer, :_reservation, :_update_flg, :_displaylist_number
    attr_accessor :projection_matrix, :view_matrix

    def initialize(w, h, bgcolor=[0, 0, 0, 0])
      @_reservation = []
      @_bgcolor = DXRuby._convert_color_dxruby_to_sdl(bgcolor)
      @_framebuffer = 0
      @_displaylist_number = 1
      return if w == 0 and h == 0

      @_texture = Image._create_gl_texture(w, h)
      @_framebuffer = glGenFramebuffer()
      glBindFramebuffer(GL_FRAMEBUFFER, @_framebuffer)
      glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, @_texture, 0)

      @_renderbuffer = glGenRenderbuffer()
      glBindRenderbuffer(GL_RENDERBUFFER, @_renderbuffer)
      glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT, w, h)
      glBindRenderbuffer(GL_RENDERBUFFER, 0)

      glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, @_renderbuffer)

      glBindFramebuffer(GL_FRAMEBUFFER, 0)

      status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
      if status != GL_FRAMEBUFFER_COMPLETE
        raise
      end

      @_width = w
      @_height = h

      @_update_flg = false
    end

    def _auto_update
      if @_reservation.empty?
        if @_update_flg
          self.clear
        end
      else
        self.update
      end
      @@_render_targets << self
    end

    def draw(model)
      prc = ->{
        glPushMatrix()
        glMultMatrixf(model.m.to_s)

        model.materials.each do |material|
          if material.image
            material.image._create_texture unless material.image._texture
          end
          material.draw
        end

        glPopMatrix()
      }
      @_reservation << [0, prc]
    end

    def clear
      glBindFramebuffer(GL_FRAMEBUFFER, @_framebuffer)
      glClearColor(@_bgcolor[0] / 255.0, @_bgcolor[1] / 255.0, @_bgcolor[2] / 255.0, @_bgcolor[3] / 255.0)
      glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
      @_update_flg = false
    end

    def update
#      glEnable(GL_MULTISAMPLE)
#      glFrontFace(GL_CCW)
#      glCullFace(GL_BACK)
      glEnable(GL_CULL_FACE)
      glEnable(GL_DEPTH_TEST)
      self.clear

      glViewport( 0, 0, @_width, @_height )
      glMatrixMode(GL_PROJECTION)
      glLoadMatrixf(@projection_matrix.to_s)

      glMatrixMode(GL_MODELVIEW)
      glLoadIdentity()
      glLoadMatrixf(@view_matrix.to_s)

      @_reservation.sort_by!{|v|v[0]}.each{|v|v[1].call}
      @_reservation.clear
      glDisable(GL_DEPTH_TEST)
      glDisable(GL_CULL_FACE)
#      glDisable(GL_MULTISAMPLE)
    end

    def width
      @_width
    end

    def height
      @_height
    end

    def bgcolor
      DXRuby._convert_color_sdl_to_dxruby(@_bgcolor)
    end

    def bgcolor=(bgcolor)
      @_bgcolor = DXRuby._convert_color_dxruby_to_sdl(bgcolor)
    end
  end
end
