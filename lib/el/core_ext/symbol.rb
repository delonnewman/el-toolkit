class Symbol
  unless method_defined?(:name)
    def name
      to_s
    end
  end
end
