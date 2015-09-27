require 'sdl2r'

module DXRuby
  module Input
    # マウスの情報
    @_mouse_button = @_mouse_x = @_mouse_y = 0
    @_old_mouse_button = @_old_mouse_x = @_old_mouse_y = 0

    # キーボードの情報
    @_keys = []
    @_old_keys = []

    # 内部情報の公開
    def self._mouse_button;@_mouse_button;end
    def self._old_mouse_button;@_old_mouse_button;end
    def self._keys;@_keys;end
    def self._old_keys;@_old_keys;end

    # マウスボタン判定用クラス
    class MouseButton
      def initialize(b) # 1が左、2が真ん中、3が右
        @_button = b
      end

      def down?
        (SDL::BUTTON(@_button) & Input._mouse_button) != 0
      end

      def push?
        (SDL::BUTTON(@_button) & Input._mouse_button) != 0 and
        (SDL::BUTTON(@_button) & Input._old_mouse_button) == 0
      end

      def release?
        (SDL::BUTTON(@_button) & Input._mouse_button) == 0 and
        (SDL::BUTTON(@_button) & Input._old_mouse_button) != 0
      end
    end

    # キーボード判定用クラス
    class Keyboard
      def initialize(k)
        @_key = k
      end

      def down?
        Input._keys[@_key]
      end

      def push?
        Input._keys[@_key] and !Input._old_keys[@_key]
      end

      def release?
        !Input._keys[@_key] and Input._old_keys[@_key]
      end
    end

    # 各種判定メソッド
    # 一応DXRuby互換で複数用意しているが中身はどれも同じ
    def self.push?(button);button.push?;end
    def self.down?(button);button.down?;end
    def self.release?(button);button.release?;end
    def self.mouse_push?(button);button.push?;end
    def self.mouse_down?(button);button.down?;end
    def self.mouse_release?(button);button.release?;end
    def self.key_push?(button);button.push?;end
    def self.key_down?(button);button.down?;end
    def self.key_release?(button);button.release?;end

    def self.mouse_x
      @_mouse_x
    end

    def self.mouse_y
      @_mouse_y
    end

    def self.x
      x = 0
      x -= 1 if K_LEFT.down?
      x += 1 if K_RIGHT.down?
      x
    end

    def self.y
      y = 0
      y -= 1 if K_UP.down?
      y += 1 if K_DOWN.down?
      y
    end

    def self.update
      # 押されているキー一覧を取得する
      @_old_keys = @_keys
      @_keys = SDL.get_keyboard_state

      # マウスの状態を取得する
      @_old_mouse_button, @_old_mouse_x, @_old_mouse_y = @_mouse_button, @_mouse_x, @_mouse_y
      @_mouse_button, @_mouse_x, @_mouse_y = SDL.get_mouse_state

      # SDL2のイベント処理
      while event = SDL.poll_event do
        case event.type
        when SDL::QUIT
          return true
        end
      end
      false
    end
  end

  # ボタン定数
  M_LBUTTON = Input::MouseButton.new(1)
  M_MBUTTON = Input::MouseButton.new(2)
  M_RBUTTON = Input::MouseButton.new(3)
  K_LEFT    = Input::Keyboard.new(SDL::SCANCODE_LEFT)
  K_RIGHT   = Input::Keyboard.new(SDL::SCANCODE_RIGHT)
  K_UP      = Input::Keyboard.new(SDL::SCANCODE_UP)
  K_DOWN    = Input::Keyboard.new(SDL::SCANCODE_DOWN)
  K_SPACE   = Input::Keyboard.new(SDL::SCANCODE_SPACE)
  K_ESCAPE  = Input::Keyboard.new(SDL::SCANCODE_ESCAPE)
  K_Z       = Input::Keyboard.new(SDL::SCANCODE_Z)
  K_X       = Input::Keyboard.new(SDL::SCANCODE_X)
  K_C       = Input::Keyboard.new(SDL::SCANCODE_C)
  K_LSHIFT  = Input::Keyboard.new(SDL::SCANCODE_LSHIFT)
  K_RSHIFT  = Input::Keyboard.new(SDL::SCANCODE_RSHIFT)
end
