module El
  class Router
    def initialize(routes = nil)
      @table = {}

      if routes
        routes.each do |(method, path, action)|
          add(method, path, action)
        end
      end
    end

    def match(method, path)
      path  = path.start_with?('/') ? path[1, path.size] : path
      parts = path.split(/\/+/)

      routes = @table[method]
      return if routes.nil?

      routes.each do |(route, action)|
        next          if route.size != parts.size
        return action if parts in route
      end

      false
    end

    def add(method, path, action)
      @table[method] ||= []
      @table[method] << [parse(path), action]
      self
    end

    private

    def parse(string)
      string.split(/\/+/).filter_map do |part|
        if part.start_with?(':')
          /\A\w\z/
        elsif part.end_with?('*')
          /^#{part[0, part.size - 1]}/i
        elsif part.empty?
          nil
        else
          part
        end
      end
    end

  end
end
