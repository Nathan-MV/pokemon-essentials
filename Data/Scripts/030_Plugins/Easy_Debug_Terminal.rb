TERMINAL_ENABLED = true
TERMINAL_KEYBIND = :F3

module Input
  unless defined?(update_Debug_Terminal)
    class << Input
      alias update_Debug_Terminal update
    end
  end

  def self.update
    update_Debug_Terminal
    if triggerex?(TERMINAL_KEYBIND) && $DEBUG && !$InCommandLine && TERMINAL_ENABLED
      $InCommandLine = true
      script = pbFreeTextNoWindow("",false,256,Graphics.width)
      $game_temp.lastcommand = script unless nil_or_empty?(script)
      begin
        pbMapInterpreter.execute_script(script) unless nil_or_empty?(script)
      rescue Exception
      end
      $InCommandLine = false
    end
  end
end

$InCommandLine = false

def pbFreeTextNoWindow(currenttext, passwordbox, maxlength, width = 240)
  window = Window_TextEntry_Keyboard_Terminal.new(currenttext, 0, 0, width, 64)
  window.maxlength = maxlength
  window.visible = true
  window.z = 99999
  window.text = currenttext
  window.passwordChar = "*" if passwordbox
  Input.text_input = true
  loop do
    Graphics.update
    Input.update
    break if Input.triggerex?(:ESCAPE) || Input.triggerex?(:RETURN)
    window.update
    yield if block_given?
  end
  Input.text_input = false
  ret = Input.triggerex?(:RETURN) ? window.text : currenttext
  window.dispose
  Input.update
  return ret
end

class Window_TextEntry_Keyboard_Terminal < Window_TextEntry
  def update
    @frame += 1
    @frame %= 20
    self.refresh if (@frame % 10) == 0
    return if !self.active
    if Input.triggerex?(:BACKSPACE) || Input.repeatex?(:BACKSPACE)
      self.delete if @helper.cursor > 0
    elsif Input.triggerex?(:UP) && $InCommandLine && !$game_temp.lastcommand.empty?
      self.text = $game_temp.lastcommand
      @helper.cursor = self.text.scan(/./m).length
    elsif ![:LEFT, :RIGHT, :RETURN, :ESCAPE].any? { |key| Input.triggerex?(key) || Input.repeatex?(key) }
      Input.gets.each_char { |c| insert(c) }
    elsif @helper.cursor > 0 && [:LEFT, :RIGHT].any? { |key| Input.triggerex?(key) || Input.repeatex?(key) }
      @helper.cursor -= 1 if Input.triggerex?(:LEFT) || Input.repeatex?(:LEFT)
      @helper.cursor += 1 if Input.triggerex?(:RIGHT) || Input.repeatex?(:RIGHT)
      @frame = 0
      self.refresh
    end
  end
end

class Game_Temp
  attr_accessor :lastcommand

  def lastcommand
    @lastcommand ||= ""
  end
end
