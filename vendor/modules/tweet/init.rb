

begin
  load_paths.each do |path|
    ActiveSupport::Dependencies.load_once_paths.delete(path)
  end
rescue Exception => e
  load_paths.each do |path|
    Dependencies.load_once_paths.delete(path)
  end
end

config.gem 'twitter', :version => '0.9.12'
