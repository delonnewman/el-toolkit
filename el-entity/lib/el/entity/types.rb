module El
  class Entity
    module Types
      def timestamp(name)
        has name, Time, edit: false, default: -> { Time.now }
      end

      def timestamps
        timestamp :created_at
        timestamp :updated_at
      end

      def password
        has :encrypted_password,
            String,
            required: false,
            display: false,
            edit: false,
            default: -> { BCrypt::Password.create(password) }

        has :password,
            :password,
            required: false,
            display: false,
            default: -> { BCrypt::Password.new(encrypted_password) }

        exclude_for_storage << :password

        :password
      end

      def email(name = :email, **options)
        has name, :email, **options
      end
    end
  end
end
