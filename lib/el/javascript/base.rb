module El
  class JavaScript
    class Base
      # add server side actions to 
      def then(proc)
        Action.new(self, proc)
      end
    end
  end
end