require 'opengl'
include OpenGL
case OpenGL.get_platform
when :OPENGL_PLATFORM_WINDOWS
  OpenGL.load_lib('opengl32.dll', 'C:/Windows/System32')
when :OPENGL_PLATFORM_MACOSX
  OpenGL.load_lib('libGL.dylib', '/System/Library/Frameworks/OpenGL.framework/Libraries')
when :OPENGL_PLATFORM_LINUX
  OpenGL.load_lib()
else
  raise RuntimeError, "Unsupported platform."
end

module OpenGL
  def glGenBuffer
    id_buf = ' ' * 4
    glGenBuffers(1, id_buf)
    id_buf.unpack('L')[0]
  end

  def glGenFramebuffer
    id_buf = ' ' * 4
    glGenFramebuffers(1, id_buf)
    id_buf.unpack('L')[0]
  end

  def glGenRenderbuffer
    id_buf = ' ' * 4
    glGenRenderbuffers(1, id_buf)
    id_buf.unpack('L')[0]
  end

  def glGenTexture
    id_buf = ' ' * 4
    glGenTextures(1, id_buf)
    id_buf.unpack('L')[0]
  end
end

class VertexBuffer
  attr_reader :types, :vertex_byte_size, :buf_id

  TypeHash = {:float=>{:type=>GL_FLOAT, :size=>4, :packstr=>"f"}}
  Name = 0
  Type = 1
  Size = 2

  def initialize(types)
    @types = types
    @vertex_class = Struct.new(*types.map{|t|t[Name]}) # 項目名の構造体を作る
    @buffer = []
    @vertex_byte_size = types.inject(0){|a, t| a += t[Size] * TypeHash[t[Type]][:size]}
    @pack_string = types.map{|t|TypeHash[t[Type]][:packstr] + t[Size].to_s}.join
    @buf_id = glGenBuffer()
  end

  def create_buffer(size)
    @buffer = Array.new(size){@vertex_class.new}
    nil
  end

  def new_vertex(*v)
    @vertex_class.new(*v)
  end

  def <<(v)
    @buffer << v
    v
  end

  def count
    @buffer.count
  end

  def [](i)
    @buffer[i]
  end

  def commit
    buf = ""
    @buffer.each do |v|
      buf << v.to_a.flatten.pack(@pack_string)
    end

    glBindBuffer(GL_ARRAY_BUFFER, @buf_id)
    glBufferData(GL_ARRAY_BUFFER, @vertex_byte_size * @buffer.count, buf, GL_STATIC_DRAW)
    glBindBuffer(GL_ARRAY_BUFFER, 0)
    nil
  end
end


class Material
  attr_accessor :shader, :image, :m
  attr_reader :vertex_buffer, :indices

  def initialize
    @index_buffer_id = glGenBuffer()
    @m = Matrix.identity(4)
  end

  def vertex_buffer=(v)
    @vertex_buffer = v
    @location = nil
  end

  def indices=(i)
    @indices = i
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, @index_buffer_id)
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, i.count * 4, i.pack("I!*"), GL_STATIC_DRAW)
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0)
  end

  def _create_location
    @location = {}
    @vertex_buffer.types.each do |t|
      @location[t[0]] = glGetAttribLocation(@shader.core.program, t[0].to_s)
    end
    nil
  end

  def _set_attributes
    pointer = 0

    @vertex_buffer.types.each do |t|
      i = @location[t[0]]
      glEnableVertexAttribArray(i)
      glVertexAttribPointer(i, t[2], VertexBuffer::TypeHash[t[1]][:type], GL_FALSE, @vertex_buffer.vertex_byte_size, pointer)
      pointer += t[2] * 4
    end
    nil
  end

  def _bind_buffer
    glBindBuffer(GL_ARRAY_BUFFER, @vertex_buffer.buf_id)
    if @indices
      glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, @index_buffer_id)
    end
  end

  def _unbind_buffer
    if @indices
      glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0)
    end
    glBindBuffer(GL_ARRAY_BUFFER, 0)
  end

  def _clear_attributes
    @vertex_buffer.types.each do |t|
      glDisableVertexAttribArray(@location[t[0]])
    end
    nil
  end

  def draw
    glPushMatrix()
    glMultMatrixf(@m.to_s)

    # Materialの描画にはShaderが必要
    glUseProgram(@shader.core.program)

    # 頂点バッファ、インデックスバッファ(あれば)のバインドを行う
    self._bind_buffer

    # 頂点シェーダのattribute位置がセットされてなければここで一覧を作る
    self._create_location unless @location

    # 頂点シェーダのattributeとバッファの位置の関連付け
    self._set_attributes

    # Shaderのuniform設定
    @shader._set_uniform

    # @imageが設定されている場合、テクスチャ0番に設定する
    if @image
      glActiveTexture(GL_TEXTURE0)
      glBindTexture(GL_TEXTURE_2D, @image._texture)
    end

    # 描画
    if @indices
      # インデックスバッファがある場合
      glDrawElements(GL_TRIANGLES, @indices.count, GL_UNSIGNED_INT, 0)
    else
      # ない場合
      glDrawArrays(GL_TRIANGLES, 0, @vertex_buffer.count)
    end

    # テクスチャユニットの解除
    shader.texture_unit.times do |i|
      glActiveTexture(OpenGL.const_get("GL_TEXTURE" + i.to_s))
      glBindTexture(GL_TEXTURE_2D, 0)
    end
    glActiveTexture(GL_TEXTURE0)

    # 頂点バッファ、インデックスバッファ(あれば)の解除を行う
    self._unbind_buffer

    # attributeの関連付けクリア
    self._clear_attributes

    glUseProgram(0)

    glPopMatrix()
  end
end

class Model
  attr_reader :materials
  attr_accessor :m, :target

  def initialize
    @materials = []
    @m = Matrix.identity(4)
    @target = nil
  end

  def draw
    @target.draw(self)
  end
end
