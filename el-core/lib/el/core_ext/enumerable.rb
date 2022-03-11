module Enumerable
  def project(*methods, **rename)
    map do |obj|
      res = methods.each_with_object({}) do |method, h|
        h.merge!(method => obj.public_send(method))
      end

      rename.each_with_object(res) do |(method, name), h|
        h.merge!(name => obj.public_send(method))
      end
    end
  end
end
