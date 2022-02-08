require_relative '../string_utils'

class String
  def underscore
    StringUtils.underscore(self)
  end

  def humanize
    StringUtils.humanize(self)
  end

  def titlecase
    StringUtils.titlecase(self)
  end

  def camelcase(**options)
    StringUtils.camelcase(self, **options)
  end

  def dasherize
    StringUtils.dasherize(self)
  end
end