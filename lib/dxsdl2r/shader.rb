require 'sdl2r'

module DXRuby
  class Shader
    def self._create_shader(type, glsl)
      s = glCreateShader(type)
      glShaderSource(s, 1, [glsl].pack('p'), 0)
      glCompileShader(s)
      rvalue_buf = ' ' * 4
      glGetShaderiv(s, GL_COMPILE_STATUS, rvalue_buf)
      rvalue = rvalue_buf.unpack('L')[0]
      if rvalue == 0
        log_buf = ' ' * 10240
        length_buf = ' ' * 4
        glGetShaderInfoLog(s, 10239, length_buf, log_buf)
        raise "Compiler log:\n#{log_buf[0, length_buf.unpack("I")[0]]}"
      end
      s
    end

    def self._create_program(vs=nil, fs=nil)
      prog_handle = glCreateProgram()
      glAttachShader(prog_handle, vs) if vs
      glAttachShader(prog_handle, fs) if fs

      glLinkProgram(prog_handle)
      rvalue_buf = ' ' * 4
      glGetProgramiv(prog_handle, GL_LINK_STATUS, rvalue_buf)
      rvalue = rvalue_buf.unpack('L')[0]
      if rvalue == 0
        log_buf = ' ' * 10240
        length_buf = ' ' * 4
        glGetProgramInfoLog(prog_handle, 10239, length_buf, log_buf)
        raise "Compiler log:\n#{log_buf[0, length_buf.unpack("I")[0]]}"
      end
      prog_handle
    end

    class Core
      attr_reader :param_def, :program, :location
      def initialize(glsl, param_def={})
        @shader = Shader._create_shader(GL_FRAGMENT_SHADER, glsl)
        @program = Shader._create_program(nil, @shader)
        @param_def = param_def
        @location = {}
        param_def.each do |k, v|
          @location[k] = glGetUniformLocation(@program, k.to_s)
        end
      end
    end

    class Core3D
      attr_reader :param_def, :program, :location
      def initialize(glsl_vs, glsl_fs, param_def={})
        @shader_vs = Shader._create_shader(GL_VERTEX_SHADER, glsl_vs) if glsl_vs
        @shader_fs = Shader._create_shader(GL_FRAGMENT_SHADER, glsl_fs) if glsl_fs
        @program = Shader._create_program(@shader_vs, @shader_fs)
        @param_def = param_def
        @location = {}
        param_def.each do |k, v|
          @location[k] = glGetUniformLocation(@program, k.to_s)
        end
      end
    end

    attr_reader :core, :param, :texture_unit

    def initialize(core)
      @core = core
      @param = {}
      core.param_def.each do |k, v|
        self.singleton_class.instance_eval do
          define_method(k) do
            @param[k]
          end
        end
        self.singleton_class.instance_eval do
          define_method(k.to_s+"=") do |arg|
            @param[k] = arg
          end
        end
      end
    end

    def _set_uniform
      @texture_unit = 1
      @param.each do |k, v|
        case @core.param_def[k]
        when :float
          case v
          when Numeric
            glUniform1f(@core.location[k], v)

          when Array
            case v.size
            when 1
              glUniform1f(@core.location[k], v[0])

            when 2
              glUniform2f(@core.location[k], v[0], v[1])

            when 3
              glUniform3f(@core.location[k], v[0], v[1], v[2])

            when 4
              glUniform4f(@core.location[k], v[0], v[1], v[2], v[3])
            end
          end

        when :int
          case v
          when Numeric
            glUniform1i(@core.location[k], v)

          when Array
            case v.size
            when 1
              glUniform1i(@core.location[k], v[0])

            when 2
              glUniform2i(@core.location[k], v[0], v[1])

            when 3
              glUniform3i(@core.location[k], v[0], v[1], v[2])

            when 4
              glUniform4i(@core.location[k], v[0], v[1], v[2], v[3])
            end
          end

        when :texture
          v._auto_update
          glActiveTexture(OpenGL.const_get("GL_TEXTURE" + @texture_unit.to_s))
          glBindTexture(GL_TEXTURE_2D, v._texture)
          glUniform1i(@core.location[k], @texture_unit)
          @texture_unit += 1

        when :fv
          case v[0]
          when Numeric
            glUniform1fv(@core.location[k], v.size, v.pack("f*"))

          when Array
            case v[0].size
            when 1
              glUniform1fv(@core.location[k], v.size, v.flatten.pack("f*"))

            when 2
              glUniform2fv(@core.location[k], v.size, v.flatten.pack("f*"))

            when 3
              glUniform3fv(@core.location[k], v.size, v.flatten.pack("f*"))

            when 4
              glUniform4fv(@core.location[k], v.size, v.flatten.pack("f*"))
            end
          end
        end
      end
    end
  end
end
