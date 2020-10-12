require 'el'

Dir['./pages/*.rb'].entries.each do |path|
  const = File.basename(path, '.rb').capitalize.to_sym
  path = File.expand_path(path)
  autoload const, path
end

El::Examples = El::Application.new([Home.new, Hello.new, Links.new, Count.new, Alert.new, Confirm.new])