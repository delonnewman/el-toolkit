class Object
  def blank?
    respond_to?(:empty?) && empty?
  end

  def present?
    !blank?
  end

  def presence
    return if blank?

    self
  end
end

class NilClass
  def blank?
    true
  end

  def presence
    self
  end
end

class String
  def blank?
    strip.empty?
  end
end
