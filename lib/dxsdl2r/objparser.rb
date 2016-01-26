class ObjParser
  attr_reader :materials

  def initialize(filename)
    self.load_obj(filename)
  end

  def load_mtl(filename)
    mtl = {}

    open(filename, "rt:utf-8") do |fh|
      text = fh.readlines
      name = nil
      text.each do |line|
        ary = line.chomp.split(" ")
        k = ary[0]
        k = k.to_sym if k
        case k
        when :newmtl
          name = ary[1].to_sym
          mtl[name] = {}
        when :Kd, :Ks, :Ka
          mtl[name][k] = [ary[1].to_f, ary[2].to_f, ary[3].to_f]
        when :Ns, :d
          mtl[name][k] = ary[1].to_f
        when :illum
          mtl[name][k] = ary[1].to_i
        when :map_Kd
          mtl[name][k] = ary[1].to_sym
        end
      end
      @mtl = mtl
    end
  end

  def load_obj(filename)
    fh = open(filename, "rt:utf-8")
    text = fh.readlines
    name = nil
    vertices = []
    texcoords = []
    normals = []
    materials = {}

    text.each do |line|
      ary = line.chomp.split(" ")
      k = ary[0]
      k = k.to_sym if k
      case k
      when :mtllib
        self.load_mtl(ary[1])
      when :v
        vertices << [Vector[ary[1].to_f, ary[2].to_f, ary[3].to_f], Vector[0, 0, 0]] # 法線データをくっつけておく
      when :vt
        texcoords << [ary[1].to_f, ary[2].to_f]
      when :vn
        normals << Vector[ary[1].to_f, ary[2].to_f, ary[3].to_f]
      when :f
        face = []
        (1...(ary.size)).each do |i|
          nums = ary[i].split("/")

          v = nums[0].to_i

          if nums.size > 1 and nums[1].size > 0
            t = nums[1].to_i
          else
            t = nil
          end

          if nums.size > 2 and nums[2].size > 0
            n = nums[2].to_i
          else
            n = nil
          end

          face << [v, t, n]
        end
        materials[name] << face

      when :usemtl
        name = ary[1].to_sym
        materials[name] = []
      end
    end

    # 法線計算
    materials.each do |k, faces|
      faces.each do |face|
        (1..(face.length-2)).each do |i|
          v0 = vertices[face[0][0] - 1]
          v1 = vertices[face[i][0] - 1]
          v2 = vertices[face[i+1][0] - 1]

          # 法線計算
          if face[0][2]
            v0[1] += normals[face[0][2]]
            v1[1] += normals[face[i][2]]
            v2[1] += normals[face[i+1][2]]
          else
            cross = (v1[0] - v0[0]).cross_product(v2[0] - v0[0])
            cross = cross.normalize if cross.norm != 0
            v0[1] += cross
            v1[1] += cross
            v2[1] += cross
          end
        end
      end
    end

    # 頂点情報生成
    @materials = {}
    c = Struct.new(:v, :n, :t)
    materials.each do |k, faces|
      @materials[k] = {}
      @materials[k][:material] = @mtl[k]
      tmp = @materials[k][:vertices] = []
      faces.each do |face|
        (1..(face.length-2)).each do |i|
          v0 = vertices[face[0][0] - 1]
          v1 = vertices[face[i][0] - 1]
          v2 = vertices[face[i+1][0] - 1]

          if @mtl[k].has_key?(:map_Kd) # テクスチャがあるときー
            tmp << c.new(v0[0], v0[1], texcoords[face[0][1] - 1])
            tmp << c.new(v1[0], v1[1], texcoords[face[i][1] - 1])
            tmp << c.new(v2[0], v2[1], texcoords[face[i+1][1] - 1])
          else # ないときー
            tmp << c.new(v0[0], v0[1], [0, 0])
            tmp << c.new(v1[0], v1[1], [0, 0])
            tmp << c.new(v2[0], v2[1], [0, 0])
          end
        end
      end
    end
  end
end
