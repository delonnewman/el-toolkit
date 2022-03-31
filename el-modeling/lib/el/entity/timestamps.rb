module El
  module Entity::Timestamps
    def timestamp(name)
      define_attribute(name, :time, default: -> { Time.now })
    end

    def timestamps
      timestamp :created_at
      timestamp :updated_at
    end
  end
end
