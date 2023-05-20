# Using mkxp-z v2.4.2/b0d8e0b - https://github.com/mkxp-z/mkxp-z/actions/runs/5033679007
$VERBOSE = nil
Font.default_shadow = false if Font.respond_to?(:default_shadow)
Graphics.frame_rate = 40
Encoding.default_internal = Encoding::UTF_8
Encoding.default_external = Encoding::UTF_8

def pbSetWindowText(string)
  System.set_window_title(string || System.game_title)
end

class Bitmap
  attr_accessor :text_offset_y

  alias mkxp_draw_text draw_text unless method_defined?(:mkxp_draw_text)

  def draw_text(x, y, width, height = nil, text = "", align = 0)
    if x.is_a?(Rect)
      x.y -= (@text_offset_y || 0)
      # rect, string & alignment
      mkxp_draw_text(x, y, width)
    else
      y -= (@text_offset_y || 0)
      height = text_size(text).height
      mkxp_draw_text(x, y, width, height, text, align)
    end
  end
end

def pbSetResizeFactor(factor)
  if !$ResizeInitialized
    Graphics.resize_screen(Settings::SCREEN_WIDTH, Settings::SCREEN_HEIGHT)
    $ResizeInitialized = true
  end

  case factor
  when 0..1
    scale = (Settings::SCREEN_SCALE * (factor + 1) / 2.0)
  when 2
    scale = (Settings::SCREEN_SCALE * factor)
  when 3
    Graphics.fullscreen = true
  else
    raise ArgumentError, "Invalid resize factor: #{factor}"
  end

  if factor.between?(0, 2)
    Graphics.fullscreen = false
    Graphics.scale = scale
    Graphics.center
  end
end

if System::VERSION != Essentials::MKXPZ_VERSION
  printf(sprintf("\e[1;33mWARNING: mkxp-z version %s detected, but this version of Pokémon Essentials was designed for mkxp-z version %s.\e[0m\r\n",
                 System::VERSION, Essentials::MKXPZ_VERSION))
  printf("\e[1;33mWARNING: Pokémon Essentials may not work properly.\e[0m\r\n")
end

def show_resolution
  if Graphics.fullscreen == true
    printf(sprintf("%sx%s fullscreen\e[0m\r\n", Graphics.width, Graphics.height))
  else
    width = (Settings::SCREEN_WIDTH * Graphics.scale).to_i
    height = (Settings::SCREEN_HEIGHT * Graphics.scale).to_i
    printf(sprintf("%sx%s scaled by %s\e[0m\r\n", width, height, Graphics.scale))
  end
end