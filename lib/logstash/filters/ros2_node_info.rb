# encoding: utf-8
require "logstash/filters/base"

class LogStash::Filters::Ros2NodeInfo < LogStash::Filters::Base
  #
  # filter {
  #   ros2_node_info {
  #     source => "message"
  #   }
  # }
  #
  config_name "ros2_node_info"
  config :source, :validate => :string, :default => "message"

  public
  def register
    # Add instance variables
  end # def register

  public
  def filter(event)
    # Essentially a simple stack-based parser based on number of spaces at
    # the start of each line
    if @source
      if event.get(@source).nil?
        event.tag("_ros2_node_info_parse_failure")
        @logger.debug? && @logger.debug("Event had no data in #{@source}")
        return [event]
      end
      last_cat = nil
      running_array = []
      event.get(@source).split("\n").each do |line|
        # No space at the start of the line - node name
	if !line.start_with?(" ")
          event.set("node", line)
        # Two spaces at the start of the line - category
	elsif /  \w/ =~ line
          unless last_cat.nil?
            # If we're tracking a category, dump it to the event before
            # starting a new one
            event.set(last_cat, running_array)
            running_array = []
          end
          last_cat = line.tr(" ", "").tr(":", "").downcase
        elsif /    [A-Za-z0-9\/]/ =~ line
          # Element of a category - split it appropriately and append it to the
          # working array
          split_line = line.tr(" ", "").split(":")
          running_array << { "topic" => split_line[0], "type" => split_line[1] }
	end
      end
      # If we have a running array and we're done parsing, dump it
      unless last_cat.nil?
        event.set(last_cat, running_array)
      end
    end
      
    # filter_matched should go in the last line of our successful code
    filter_matched(event)
  end # def filter
end # class LogStash::Filters::Ros2NodeInfo
