=begin
  Made by Christian KAKESA etna_2008(paris) <christian.kakesa@gmail.com>
=end

begin
  require 'gtk2'
rescue LoadError
  puts "Error: #{$!}"
  exit
end

class RsTooltip < Gtk::Tooltips
  def initialize(parent_widget = nil, parent_win = nil)
    super()
    @current_iter = nil
    @parent_widget = parent_widget
    @parent_win = parent_win
    if @parent_widget
      @parent_widget.signal_connect("motion-notify-event") do |widget, event|
        path, column, x, y = @parent_widget.get_path_at_pos(event.x, event.y)
        if path
          iter = @parent_widget.model.get_iter(path)
          if (iter && iter != @current_iter)
          	if !iter.has_child?()
          		set_tip(@parent_widget, build_text(iter), nil)
            else
            	set_tip(@parent_widget, "", nil)
            end
            @current_iter = iter
          end
        end
      end
    end
  end
  def build_text(iter)
    res  = "#{iter[3].to_s}\n"
    res += "Session   : #{iter[4].to_s}\n"
    res += "Status    : #{iter[5].to_s}\n"
    res += "User data : #{iter[6].to_s}\n"
    res += "Location  : #{iter[7].to_s}\n"
    return res
  end
end

