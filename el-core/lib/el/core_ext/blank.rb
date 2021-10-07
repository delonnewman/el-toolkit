class Object
  def blank?
    respond_to?(:empty?) && empty?
  end

  def present?
    !blank?
  end
end

class NilClass
  def blank?
    true
  end
end

class String
  def blank?
    strip.empty?
  end
end
