# coding: utf-8

require './mmdr.rb'

class MMDMotion
    attr_reader :header
    attr_reader :motions
    attr_reader :skins

    def self.load_file(filename)
      fh = open(filename, "rt:Shift_JIS")
      motion = MMDMotion.new(fh)
      fh.close
      motion
    end

    def initialize(io)
        reader = MMDReader.new(io)

        @header = load_header(reader)
        @motions = load_motions(reader)
        @skins = load_skins(reader)
    end

    def load_header(reader)
        header = MMDMotionHeader.new()
        header.load(reader)

        return header
    end

    def load_motions(reader)
        motions = Array.new()

        reader.int().times{|index|
            motion = MMDMotionData.new()
            motion.load(reader)
            motions[index] = motion
        }

        motions.sort! do |motion1, motion2|
            motion1.flame_no <=> motion2.flame_no
        end

        return motions
    end

    def load_skins(reader)
        skins = Array.new()

        reader.int().times{|index|
            skin = MMDSkinMotion.new()
            skin.load(reader)

            skins[index] = skin
        }

        skins.sort! do |skin1, skin2|
            skin1.flame_no <=> skin2.flame_no
        end

        return skins
    end
end

class MMDMotionHeader
    attr_reader :header
    attr_reader :name

    def load(reader)
        @header = reader.string(30)
        @name = reader.string(20)
    end
end

class MMDMotionData
    attr_reader :bone_name
    attr_reader :flame_no
    attr_reader :location
    attr_reader :rotation
    attr_reader :interpolation

    def load(reader)
        @bone_name = reader.string(15)
        @flame_no = reader.int()
        @location = Vector.new(*reader.floats(3))
        @rotation = Quaternion.new(*reader.floats(4))
        @interpolation = reader.bytes(64)

        @location[2] = -@location[2]
        @rotation[0] = -@rotation[0]
        @rotation[1] = -@rotation[1]
    end
end

class MMDSkinMotion
    attr_reader :name
    attr_reader :flame_no
    attr_reader :weight

    def load(reader)
        @name = reader.string(15)
        @flame_no = reader.int()
        @weight = reader.float()
    end
end
