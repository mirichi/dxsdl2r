# coding: utf-8

class MMDReader
    def initialize(io)
        @io = io
    end

    def byte()
        return @io.read(1).unpack('C')[0]
    end

    def bytes(count)
        return @io.read(count).unpack("C#{count}")
    end

    def short()
        return @io.read(2).unpack('s')[0]
    end

    def ushort()
        return @io.read(2).unpack('S')[0]
    end

    def ushorts(count)
        return @io.read(2 * count).unpack("S#{count}")
    end

    def int()
        return @io.read(4).unpack('i')[0]
    end

    def float()
        return @io.read(4).unpack('f')[0]
    end

    def floats(count)
        return @io.read(4 * count).unpack("f#{count}")
    end

    def string(count)
        return @io.read(count).unpack('Z*')[0]
    end

    def eof?()
        return @io.eof?()
    end
end
