require 'sdl2r'

module DXRuby
  class Font
    attr_accessor :_font

    # {�t�@�C����=>{�t�F�C�X�̃t�@�~���[��=>index}}�Ƃ����n�b�V���ŏ���ێ�����
    @@_fonts = {}

    def self.install(filename)
      tmp = {}
      result = []

      # ���𓾂邽�߂ɂƂ肠����open���Ă݂�
      font = SDL::TTF.open_font(filename, 24)
      name = SDL::TTF.font_face_family_name(font)
      tmp[name] = 0
      result << name

      # �����t�F�C�X����ꍇ�͑S��open���Ă݂�
      (1...SDL::TTF.font_faces(font)).each do |i|
        fontt = SDL::TTF.open_font_index(filename, 24, i)
        name = SDL::TTF.font_face_family_name(fontt)
        tmp[name] = i
        result << name
        SDL::TTF.close_font(fontt)
      end
      SDL::TTF.close_font(font)

      @@_fonts[filename] = tmp
      result
    end

    def initialize(size, fontname="IPAGothic")
      @@_fonts.each do |filename, hash|
        if hash.include?(fontname)
          @_font = SDL::TTF.open_font_index(filename, size, hash[fontname])
          break
        end
      end
      raise unless @_font
    end

    self.install("./font/ipag.ttf")
    @_default_font = Font.new(24)

    def self.default
      @_default_font
    end
  end
end
