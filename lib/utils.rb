module Utils
  def formatted_time(time_value)
    DateTime.strptime(time_value, '%s').strftime("%F %T %z")
  end

  def format_output(obj)
    if obj.is_a?(String)
      obj
    elsif obj.is_a?(Array)
      obj.join(',')
    else
      raise ArgumentError
    end
  end

  def write_to_output(output_type, obj)
    str = Utils.format_output(obj)
    output_file(output_type).write(str + "\n")
  end

  def eight_decimals(f)
    f = f.is_a?(String) ? f.to_f : f
    sprintf('%.8f', f.round(8)) if f != 0
  end

  def output_file(output_type)
    @output_files ||= {}
    file_path = File.join($config.output_path, OUTPUT_FILES_MAPPING[output_type])
    @output_files[output_type] ||= File.new(file_path, "w")
  end

  def close_outputs
    (@output_files || {}).each_pair do |k, v|
      v.close
    end
  end
end
