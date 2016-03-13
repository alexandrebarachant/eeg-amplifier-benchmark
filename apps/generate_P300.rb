require 'gosu'
require 'csv'
require 'distribution'

class Square
    attr_accessor :color
    def initialize(window, x, y, size=50)
        @x = x
        @y = y
        @size = size
        @color = 0x2fffffff
        @window = window
    end

    def draw
        @window.draw_quad(@x-@size, @y-@size, @color, @x+@size, @y-@size,
                          @color, @x-@size, @y+@size, @color, @x+@size,
                          @y+@size, @color, 0)
    end
end

class Group
    attr_accessor :is_target
    def initialize(id)
        @is_target = 1
        @id = id
        @squares = []
    end

    def push(sq)
        @squares.push(sq)
    end

    def flash
        @squares.each { |sq| sq.color = 0xffffffff  }
    end

    def unflash
        @squares.each { |sq| sq.color = 0x2fffffff  }
    end
end

class GameWindow < Gosu::Window
  def initialize
    super 800, 800
    self.caption = "P300 generator"
    @frame = 0
    @gid = 1
    @isi = 20 # in number of frame
    @stimlenght = 4
    @odd = 0
    @prob = 85
    @stimcount = 0
    @timestamp = []
    @state = 'Init'
    @distrib = Distribution::Exponential.rng(1.0/@isi)

    @nrows = 6
    @ncols = 6

    @order = []
    @Nrep = 10
    @repetitions = 0
    #target = [rand(@nrows) + 1, rand(@ncols) + 1]
    #generate_group(@nrows, @ncols, [2 , 4])

  end

  def generate_group(nrows, ncols, target)
      @groups = Hash.new
      @order = (1..(nrows+ncols)).to_a.shuffle!

      #create groups`
      (1..nrows).each{|i| @groups[i] = Group.new(i)}
      (1..ncols).each{|i| @groups[i + nrows] = Group.new(i + nrows)}

      @elements = []
      for i in 1..nrows
          x_step = ( 800/ (2*nrows) )
          size = (x_step / 2)*1.5
          x = x_step + 2 * (i-1) * x_step
          for j in 1..ncols
              y_step = ( 800/ (2*ncols) )
              y = y_step + 2 * (j-1) * y_step
              sq = Square.new(self, x, y, size=size)
              @elements.push(sq)

          end
      end

      @elements.shuffle!
      for i in 1..nrows
          for j in 1..ncols
              ix = (nrows)*(i-1) + (j-1)
              sq = @elements[ix]
              if (i==target[0]) & (j==target[1])
                  @groups[i].is_target = 2
                  @groups[nrows + j].is_target = 2
                  sq.color = 0xffff002d
              end

              @groups[i].push(sq)
              @groups[nrows + j].push(sq)
          end
      end

  end

  def update
      case @state
      when 'Init'
          @t = Gosu::milliseconds
          target = [rand(@nrows) + 1, rand(@ncols) + 1]
          generate_group(@nrows, @ncols, target)
          @state = 'Display_target'
          @stimcount = 0

      when 'Display_target'
          if (Gosu::milliseconds - @t) > 3000
              @state = 'Flashing'
              @t = Gosu::milliseconds
          end
      when 'Flashing'
          rep = (@stimcount) / (@nrows + @ncols)
          if rep / @Nrep == 1
              @stimcount = 0
              @state = 'New Target'
              @t = Gosu::milliseconds
          end
      when 'New Target'
          if (Gosu::milliseconds - @t) > 1000
              @state = 'Init'
          end
      end

  end

  def draw
      case @state
      when 'Flashing'
          if (@frame) < @stimlenght
              if @frame==0
                  @gid = @order[(@stimcount % @groups.length)]
                  @odd = @groups[@gid].is_target
                  @groups[@gid].flash()
                  @timestamp << [Time.now().to_f, @odd, @gid ]
              end
          else
              @groups[@gid].unflash()
          end
          if @frame == @isi
              @frame = 0
              @stimcount += 1
              @isi = (@distrib.call).to_i
              if @isi > 40
                  @isi = 40
              end
              if @isi < 8
                  @isi = 8
              end
          else
              @frame += 1
          end
      when 'New Target'


      end

      @elements.each{|e| e.draw()}

  end

  def button_down(id)
      if id == Gosu::KbEscape
          CSV.open("P300_timestamp_2.csv", "wb") do |csv|

              csv << ["timestamp", "target", "group"]
              @timestamp.each do |t|
                  csv << t
              end
          end
          close
      end
  end
end

window = GameWindow.new
window.show
