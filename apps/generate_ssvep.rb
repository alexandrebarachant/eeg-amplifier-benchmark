require 'gosu'

class GameWindow < Gosu::Window
  def initialize
    super 600, 600
    self.caption = "SSVEP generator"
    @frame = 0
    @freq = 2 # in number of frame
    puts "Flashing frequency : #{30.0/@freq} Hz"
  end

  def update
      @frame += 1
      if (@frame/(@freq) % 2)==1
          @color = 0xffffffff
      else
          @color = 0x00000000
      end
  end

  def draw
      x = 300
      y = 300
      size = 300
      draw_quad(x-size, y-size, @color, x+size, y-size, @color, x-size,
                y+size, @color, x+size, y+size, @color, 0)
  end

  def button_down(id)
      if id == Gosu::KbEscape
          close
      end
  end
end

window = GameWindow.new
window.show
