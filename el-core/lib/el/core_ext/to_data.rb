class Object
  def to_data(namespace = self.class.name)
    return to_h.to_data(namespace) if respond_to?(:to_h)

    instance_variables.each_with_object({}) do |var, data|
      data[var.to_data(namespace)] = instance_variable_get(var).to_data
    end
  end
end

class Struct
  def to_data(namespace = self.class.name)
    to_h.to_data(namespace)
  end
end

class Symbol
  def to_data(namespace = nil)
    return self unless namespace || name.start_with?('@')

    :"#{namespace}::#{name.tr('@', '')}"
  end
end

class String
  def to_data(namespace = nil)
    return self unless namespace

    "#{namespace}::#{self}"
  end
end

class NilClass
  def to_data
    self
  end
end

class TrueClass
  def to_data
    self
  end
end

class FalseClass
  def to_data
    self
  end
end

class Numeric
  def to_data
    self
  end
end

module Enumerable
  def to_data
    map(&:to_data)
  end

  def navigate(&block)
    each(&block)
  end
end

class Hash
  def to_data(namespace = nil)
    reduce({}) do |h, (k, v)|
      h.merge(k.to_data(namespace) => v.to_data)
    end
  end
end
