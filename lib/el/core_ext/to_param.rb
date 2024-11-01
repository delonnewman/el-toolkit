class Object
  alias to_param to_s

  def to_query(key)
    "#{CGI.escape(key.to_param)}=#{CGI.escape(to_param.to_s)}"
  end
end

class NilClass
  def to_param
    self
  end
end

class TrueClass
  def to_param
    self
  end
end

class FalseClass
  def to_param
    self
  end
end

class Array
  def to_param
    map(&:to_param).join('/')
  end

  def to_query(key)
    prefix = "#{key}[]"

    if empty?
      nil.to_query(prefix)
    else
      map { |value| value.to_query(prefix) }.join('&')
    end
  end
end

class Hash
  def to_query(namespace = nil)
    query = filter_map do |key, value|
      unless (value.is_a?(Hash) || value.is_a?(Array)) && value.empty?
        value.to_query(namespace ? "#{namespace}[#{key}]" : key)
      end
    end

    query.sort! unless namespace.to_s.include?('[]')
    query.join('&')
  end

  alias to_param to_query
end
