require 'json'
require_relative 'memory'

module El
  module ActionStores
    class File
      def initialize(file)
        @file   = file
        @actions = {}

        at_exit do
          ::File.unlink(@file) if ::File.exists?(@file)
        end
      end

      def get(id)
        @actions[id]
      end

      def list
        @actions.values
      end

      def set(action)
        @actions[action.id] = action

        thread = Thread.new do
          ::File.open("#{@file}-#{thread.object_id}", 'w') do |f|
            list.each do |action|
              f.puts action.serialize!
            end
          end

          ::File.symlink("#{@file}-#{thread.object_id}", @file)

          @actions = IO.read(@file).lines.map do |line|
            action = Action.deserialize(line)
            [action.id, action]
          end.to_h

          @actions.each do |(id, action)|
            pp action
            @action.call
          end
        end
      end
    end
  end
end

store = El::ActionStores::File.new('test.db')
store.set(El::Action.new(->{ puts "test" }))