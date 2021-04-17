module El
  class Struct
    class << self
      def new(*attributes)
        Class.new do
          attributes.each do |attr|
            attr_reader attr
          end

          def initialize(**attributes)
            attributes.each_pair do |name, value|
              instance_variable_set(:"@#{name}", value)
            end
          end
        end
      end
    end
  end
end
