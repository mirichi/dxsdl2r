Dir.chdir(File.dirname(__FILE__))
require_relative './../lib/dxsdl2r'
require_relative './mmd'
require_relative './motion'


src_vs = <<EOF
uniform vec3 boneOrigin[32];
uniform vec4 boneRotation[32];
uniform vec3 bonePosition[32];
uniform bool isEdge;
attribute float boneWeight;
attribute vec3 normal;
attribute vec2 texcoord;
attribute vec3 position;
attribute float index1;
attribute float index2;
varying vec3 vPosition;
varying vec3 vNormal;
varying vec2 vTexCoord;

vec3 qtransform(vec4 q, vec3 v) {
    return v + 2.0 * cross(cross(v, q.xyz) - q.w*v, q.xyz);
}

void main(void)
{
  int i1 = int(index1);
  int i2 = int(index2);
  vec3 t_localpos = position - boneOrigin[i1];
  vec3 t_position = qtransform(boneRotation[i1], t_localpos) + bonePosition[i1];
  vec3 t_normal = qtransform(boneRotation[i1], normal);

  vPosition = (gl_ModelViewProjectionMatrix * vec4(t_position, 1.0)).xyz;
  vNormal = gl_NormalMatrix * t_normal;

  if (boneWeight < 0.99) {
    vec3 t_localpos2 = position - boneOrigin[i2];
    vec3 p2 = qtransform(boneRotation[i2], t_localpos2) + bonePosition[i2];
    vec3 n2 = qtransform(boneRotation[i2], normal);

    t_position = mix(p2, t_position, boneWeight);
    t_normal = normalize(mix(n2, t_normal, boneWeight));
  }

  if (isEdge) {
      vec4 pos = gl_ModelViewProjectionMatrix * vec4(t_position, 1.0);
      vec4 pos2 = gl_ModelViewProjectionMatrix * vec4(t_position + t_normal, 1.0);
      vec4 norm = normalize(pos2 - pos);
      gl_Position = pos + norm * 0.05;
      return;
  }

    vTexCoord = texcoord;
    gl_Position = gl_ModelViewProjectionMatrix * vec4(t_position, 1.0);
}
EOF

src_fs = <<EOF
uniform bool isEdge;
uniform bool useTexture;
uniform bool isSphereAdd;
uniform bool isSphereUse;

uniform float alpha;
uniform float shininess;

uniform sampler2D sampler;
uniform sampler2D toonSampler;
uniform sampler2D sphereSampler;

uniform vec3 ambient;
uniform vec3 diffuse;
uniform vec3 specularColor;
uniform vec3 lightDir;
uniform vec3 lightDiffuse;

varying vec3 vPosition;
varying vec3 vNormal;
varying vec2 vTexCoord;

vec4 edgeColor = vec4(0.0, 0.0, 0.0, 1.0);

void main (void)
{
    if(isEdge){
        gl_FragColor = edgeColor;
    }else{
        vec3 cameraDir = normalize(-vPosition);
        vec3 halfAngle = normalize(lightDir + cameraDir);
        float specularWeight = pow(max(0.001, dot(halfAngle, normalize(vNormal))) , shininess);
        vec3 specular = specularWeight * specularColor;

        vec3 color = ambient + lightDiffuse * (diffuse + specular);

        if(useTexture){
            color *= texture2D(sampler, vTexCoord).rgb;
        }

        if(isSphereUse){
            vec2 sphereCoord = 0.5 * (1.0 + vec2(1.0, -1.0) * normalize(vNormal).xy);

            if(isSphereAdd){
                color += texture2D(sphereSampler, sphereCoord).rgb;
            }else{
                color *= texture2D(sphereSampler, sphereCoord).rgb;
            }
        }

        color = clamp(color, 0.0, 1.0);

        float dotNL = max(0.0, dot(normalize(lightDir), normalize(vNormal)));
        vec2 toonCoord = vec2(0.0, 0.5 * (1.0 - dotNL));
        vec3 toon = texture2D(toonSampler, toonCoord).rgb;
        gl_FragColor = vec4(color * toon, alpha);
    }
}
EOF

core = Shader::Core3D.new(src_vs, src_fs, isEdge: :int,
                                          useTexture: :int,
                                          isSphereAdd: :int,
                                          isSphereUse: :int,
                                          alpha: :float,
                                          shininess: :float,
                                          sampler: :texture,
                                          toonSampler: :texture,
                                          sphereSampler: :texture,
                                          ambient: :float,
                                          diffuse: :float,
                                          specularColor: :float,
                                          lightDir: :float,
                                          lightDiffuse: :float,
                                          boneOrigin: :fv,
                                          boneRotation: :fv,
                                          bonePosition: :fv
                                          )

class BoneManager
  attr_reader :bones, :count
  def initialize
    @m_b_map = {}
  end

  def add_bone(material, bone)
    if @m_b_map.has_key?(material)
      if @m_b_map[material].has_key?(bone)
        return @m_b_map[material][bone]
      else
        @m_b_map[material][bone] = @m_b_map[material].size
      end
    else
      @m_b_map[material] = {bone=>0}
    end
    @m_b_map[material].size - 1
  end

  def commit
    @m_b_map.each do |material, bones|
      material.shader.boneOrigin = bones.keys.map{|bone|bone.pos} + [[0,0,0]]*(32-bones.size)
      material.shader.boneRotation = bones.keys.map{|bone|bone.arot} + [[0,0,0]]*(32-bones.size)
      material.shader.bonePosition = bones.keys.map{|bone|bone.apos} + [[0,0,0]]*(32-bones.size)
    end
  end
end

mmd = MMDModel.load_file("./mmd/Lat式ミクVer2.31_Normal.pmd")
#mmd = MMDModel.load_file("./Lat式ミクVer2.31_Sailor夏服エッジ無し専用.pmd")

bone_manager = BoneManager.new

# トゥーンテクスチャ読み込み
toons = mmd.toon_texture.names.map.with_index{|name, i|
  tmp = name.force_encoding("Shift_JIS").encode("UTF-8",:invalid => :replace, :replace => "")

  if tmp and tmp.end_with?(".bmp")
    Image.load("./mmd/" + tmp)
  else
    Image.load("./mmd/toon" + (i + 1).to_s.rjust(2, "0") + ".bmp")
  end
} + [Image.load("./mmd/toon00.bmp")]

# モデルデータ作成
model = Model.new
i = 0
hash = {}

mmd.materials.each do |m|
  material = Material.new
  material.shader = Shader.new(core)

  # 頂点バッファ生成
  v = VertexBuffer.new([
      [:position, :float, 3],
      [:normal, :float, 3],
      [:texcoord, :float, 2],
      [:boneWeight, :float, 1],
      [:index1, :float, 1],
      [:index2, :float, 1]
    ]
  )

  # 頂点情報設定
  m.vert_count.times do
    pos    = mmd.vertices[mmd.face.indices[i]].pos
    normal = mmd.vertices[mmd.face.indices[i]].normal
    uv     = mmd.vertices[mmd.face.indices[i]].uv
    bones  = mmd.vertices[mmd.face.indices[i]].bone_nums
    weight  = mmd.vertices[mmd.face.indices[i]].bone_weight

    i1 = bone_manager.add_bone(material, mmd.bones[bones[0]])
    i2 = bone_manager.add_bone(material, mmd.bones[bones[1]])

    v << v.new_vertex(pos, normal, uv, [weight], [i1], [i2])
    i += 1
  end

  v.commit

  # テクスチャ
  if m.texture
    material.shader.useTexture = 1
    material.shader.sampler = Image.load("./mmd/" + m.texture)
  else
    material.shader.useTexture = 0
  end

  # スフィアマップ
  if m.sphere
    material.shader.isSphereUse = 1
    material.shader.sphereSampler = Image.load("./mmd/" + m.sphere)
    if m.sphere.end_with?('.spa')
      material.shader.isSphereAdd = 1
    else
      material.shader.isSphereAdd = 0
    end
  else
    material.shader.isSphereUse = 0
  end

  # トゥーン
  toon_index = m.toon_index
  toon_index = 10 if toon_index > 10 or toon_index < 0
  material.shader.toonSampler = toons[toon_index]

  # シェーダのパラメータ設定
  material.shader.isEdge = 0
  material.shader.alpha = m.alpha
  material.shader.diffuse = m.diffuse
  material.shader.specularColor = m.specular
  material.shader.lightDiffuse = [0.6, 0.6, 0.6]
  material.shader.lightDir = [-0.5, -1.0, 0.5]
  material.shader.ambient = m.ambient
  material.shader.shininess = m.specularity

  # 頂点セットと内部処理起動
  material.vertex_buffer = v
#  material.commit # 頂点の値を変えたらこれが必要

  model.materials << material
end

# モーション読み込み
motion = MMDMotion.load_file("./mmd/kashiyuka.vmd")
#motion = MMDMotion.load_file("kishimen.vmd")

# ボーンを名前で検索するためのハッシュ
bones_hash = {}
mmd.bones.each do |bone|
  bones_hash[bone.name] = bone
end

Window.width = 1024
Window.height = 768
rt3d = RenderTarget3D.new(Window.width, Window.height)
rt3d.projection_matrix = Matrix.perspective(30.0, Window.width.to_f / Window.height, 3.0, 1000.0)
rt3d.view_matrix = Matrix.look_at([0, 10, 100], [0, 10, 0], [0, 1, 0])
model.target = rt3d

flame = 0
Window.fps = 30
Window.loop do

  motion.motions.each do |m|
    next if m.flame_no != flame
    next if bones_hash[m.bone_name] == nil
    bones_hash[m.bone_name].pos = Vector.new(*(bones_hash[m.bone_name].pos))
    bones_hash[m.bone_name].mpos = Vector.new(*m.location)
    bones_hash[m.bone_name].mrot = Quaternion.new(*m.rotation)
  end

  mmd.bones.each do |bone|
    if bone.parent_index == -1 # センターボーン
      bone.apos = bone.pos + bone.mpos
      bone.arot = bone.mrot
    else
      parent_bone = mmd.bones[bone.parent_index]

      # 位置計算
      v = (bone.pos - parent_bone.pos + bone.mpos)
      bone.apos = v.rotate_by_quat(parent_bone.arot) + parent_bone.apos

      # 回転計算
      bone.arot = bone.mrot * parent_bone.arot
    end
  end
  bone_manager.commit

  model.draw

  Window.draw(0, 0, rt3d)
  break if Input.key_push?(K_ESCAPE)
  flame += 1
end
