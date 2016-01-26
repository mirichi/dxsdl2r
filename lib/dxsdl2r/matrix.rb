module DXRuby
  class Vector < Array
    @@to_rad = Math::PI / 180.0

    def x;self[0];end
    def y;self[1];end
    def z;self[2];end
    def w;self[3];end
    def xy;Vector.new(*self[0..1]);end
    def xyz;Vector.new(*self[0..2]);end

    def self.dot_product(v1, v2)
      v1.dot_product(v2)
    end

    def self.cross_product(v1, v2)
      v1.cross_product(v2)
    end

    def initialize(*v)
      super()
      self.concat(v)
    end

    def +(v)
      case v
      when Vector
        Vector.new(*self.map.with_index{|s, i|s + (v[i] ? v[i] : 0)})
      when Array
        Vector.new(*self.map.with_index{|s, i|s + (v[i] ? v[i] : 0)})
      when Numeric
        Vector.new(*self.map{|s|s + v})
      else
        nil
      end
    end

    def -(v)
      case v
      when Vector
        Vector.new(*self.map.with_index{|s, i|s - (v[i] ? v[i] : 0)})
      when Array
        Vector.new(*self.map.with_index{|s, i|s - (v[i] ? v[i] : 0)})
      when Numeric
        Vector.new(*self.map{|s|s - v})
      else
        nil
      end
    end

    def *(v)
      case v
      when Numeric
        Vector.new(*self.map{|s|s * v})
      when Vector
        self.dot_product v
      when Matrix
        result = Vector.new
        i = 0
        self_size = self.size
        m_size = v.size
        while i < m_size
          data = 0
          j = 0
          while j < self_size
            data += self[j] * v[j][i]
            j += 1
          end
          result << data
          i += 1
        end
        result
      end
    end

    def dot_product(v)
      s = self.size
      i = 0
      t = 0
      while i < s
        t += self[i] * v[i]
        i += 1
      end
      t
    end

    def cross_product(v)
        result = Vector.new
        result << self[1] * v[2] - self[2] * v[1]
        result << self[2] * v[0] - self[0] * v[2]
        result << self[0] * v[1] - self[1] * v[0]
        result
    end

    def norm2
        result = 0

        i = 0
        self_size = self.size
        while i < self_size
          result += self[i] * self[i]
          i += 1
        end
        result
    end

    def norm
        Math.sqrt(norm2())
    end

    def normalize
        length = self.norm

        i = 0
        self_size = self.size
        result = Vector.new
        while i < self_size
          result << self[i] / length
          i += 1
        end
        result
    end

    def rotate_by_quat(quat)
        x = self[0]
        y = self[1]
        z = self[2]

        qx = quat[0]
        qy = quat[1]
        qz = quat[2]
        qw = quat[3]

        ix = qw * x + qy * z - qz * y
        iy = qw * y + qz * x - qx * z
        iz = qw * z + qx * y - qy * x
        iw = -qx * x - qy * y - qz * z

        result = Vector.new
        result << ix * qw + iw * -qx + iy * -qz - iz * -qy
        result << iy * qw + iw * -qy + iz * -qx - ix * -qz
        result << iz * qw + iw * -qz + ix * -qy - iy * -qx
    end

    def to_s
      self.pack("f*")
    end
  end

  class Matrix < Array
    @@to_rad = Math::PI / 180.0

    def initialize(*arr)
      super()
      self.concat(Array.new(arr.size) {|i| Vector.new(*arr[i])})
    end

    @@identity3 = Matrix.new([1,0,0], [0,1,0], [0,0,1])
    @@identity4 = Matrix.new([1,0,0,0], [0,1,0,0], [0,0,1,0], [0,0,0,1])

    def self.identity(s)
      case s
      when 3
        @@identity3
      when 4
        @@identity4
      end
    end

    def *(a)
      s = a.size
      i = 0
      result = []
      while i < s
        result.push(self[i] * a)
        i += 1
      end

      a.class.new(*result)
    end

    def self.rotation(angle)
      rad = @@to_rad * angle
      cos = Math.cos(rad)
      sin = Math.sin(rad)
      Matrix.new(
       [ cos, sin, 0],
       [-sin, cos, 0],
       [   0,   0, 1]
      )
    end

    def self.rotation_z(angle)
      rad = @@to_rad * angle
      cos = Math.cos(rad)
      sin = Math.sin(rad)
      Matrix.new(
       [ cos, sin, 0, 0],
       [-sin, cos, 0, 0],
       [   0,   0, 1, 0],
       [   0,   0, 0, 1]
      )
    end

    def self.rotation_x(angle)
      rad = @@to_rad * angle
      cos = Math.cos(rad)
      sin = Math.sin(rad)
      Matrix.new(
       [   1,   0,   0, 0],
       [   0, cos, sin, 0],
       [   0,-sin, cos, 0],
       [   0,   0,   0, 1]
      )
    end

    def self.rotation_y(angle)
      rad = @@to_rad * angle
      cos = Math.cos(rad)
      sin = Math.sin(rad)
      Matrix.new(
       [ cos,   0,-sin, 0],
       [   0,   1,   0, 0],
       [ sin,   0, cos, 0],
       [   0,   0,   0, 1]
      )
    end

    def self.translation(x, y, z = nil)
      if z
        Matrix.new(
         [   1,   0,   0,   0],
         [   0,   1,   0,   0],
         [   0,   0,   1,   0],
         [   x,   y,   z,   1]
        )
      else
        Matrix.new(
         [   1,   0,   0],
         [   0,   1,   0],
         [   x,   y,   1]
        )
      end
    end

    def self.perspective(fovy, aspect, znear, zfar)
      radian = 2 * Math::PI * fovy / 360.0
      t = (1.0 / Math.tan(radian / 2))
      Matrix.new(
        [t / aspect, 0, 0, 0],
        [0, t, 0, 0],
        [0, 0, (zfar + znear) / (znear - zfar), -1],
        [0, 0, (2 * zfar * znear) / (znear - zfar), 0]
      )
    end

    def self.look_at(eye, center, up)
      eye    = Vector.new(*eye)
      center = Vector.new(*center)
      up     = Vector.new(*up)
      forward = (center - eye).normalize
      side = forward.cross_product(up).normalize
      up = side.cross_product(forward)
      Matrix.new(
        [side.x, up.x, -forward.x, 0],
        [side.y, up.y, -forward.y, 0],
        [side.z, up.z, -forward.z, 0],
        [0,0,0,1]
      ) * Matrix.translation(-eye.x, -eye.y, -eye.z)
    end

    def to_s
      self.inject(""*1){|s, v|s << v.to_s}
    end
  end

  class Quaternion < Array
    @@to_rad = Math::PI / 180.0

    def x;self[0];end
    def y;self[1];end
    def z;self[2];end
    def w;self[3];end
    def xy;Vector.new(*self[0..1]);end
    def xyz;Vector.new(*self[0..2]);end

    def initialize(*v)
      super()
      self.concat(v)
    end

    def *(v)
      a = self
      b = v
      result = Quaternion.new

      result << a[3] * b[0] + a[0] * b[3] + a[1] * b[2] - a[2] * b[1]
      result << a[3] * b[1] - a[0] * b[2] + a[1] * b[3] + a[2] * b[0]
      result << a[3] * b[2] + a[0] * b[1] - a[1] * b[0] + a[2] * b[3]
      result << a[3] * b[3] - a[0] * b[0] - a[1] * b[1] - a[2] * b[2]

      result
    end

    def conj
      Quaternion.new(-self[0], -self[1], -self[2], self[3])
    end

    def self.rotation(v, rot)
      rad = rot * @@to_rad
      s = Math::sin(rad * 0.5)
      Quaternion.new(v[0] * s, v[1] * s, v[2] * s, Math::cos(rad * 0.5))
    end

    def self.rotate(v, axis, rot)
      q = rotation(axis, rot)
      r = q.conj
      (r * Quaternion.new(*v, 0) * q).xyz
    end

    def slerp(other, value)
      cosHalfTheta = self[0] * other[0] + self[1] * other[1] + self[2] * other[2] + self[3] * other[3]

      if cosHalfTheta.abs() >= 1.0
          return self.dup
      end

      halfTheta = Math.acos(cosHalfTheta)
      sinHalfTheta = Math.sqrt(1.0 - cosHalfTheta * cosHalfTheta)

      if sinHalfTheta.abs() < 0.001
        result = Quaternion.new
        result << (self[0] * 0.5 + other[0] * 0.5)
        result << (self[1] * 0.5 + other[1] * 0.5)
        result << (self[2] * 0.5 + other[2] * 0.5)
        result << (self[3] * 0.5 + other[3] * 0.5)
        return result
      end

      ratioA = Math.sin((1 - value) * halfTheta) / sinHalfTheta
      ratioB = Math.sin(value * halfTheta) / sinHalfTheta

      result = Quaternion.new
      result << (self[0] * ratioA + other[0] * ratioB)
      result << (self[1] * ratioA + other[1] * ratioB)
      result << (self[2] * ratioA + other[2] * ratioB)
      result << (self[3] * ratioA + other[3] * ratioB)
      result
    end
  end
end
