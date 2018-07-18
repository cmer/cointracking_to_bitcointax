Config = Struct.new(:cointracking_api_key, :cointracking_secret_key, :output_path, :read_from_cache, :cache_data_path) do
  def cache_data_path
    File.expand_path(self[:cache_data_path]) if self[:cache_data_path]
  end

  def output_path
    File.expand_path(self[:output_path]) if self[:output_path]
  end

  def load(config_file = nil)
    if config_file.blank?
      path = ROOT_PATH
      config_file = File.join(path, 'config.yml')
    end

    h = YAML.load_file(File.expand_path(config_file))

    self.members.each do |m|
      self.send("#{m}=", nil)
    end

    h.each_pair do |k, v|
      self.send("#{k}=", v)
    end
    self
  end
end
