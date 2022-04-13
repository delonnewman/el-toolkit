module El
  # TODO: make into a plugin
  module Entity::Passwords
    El::Types.define_alias(:password, ->(v) { v.is_a?(String) && v.length > 10 || v.is_a?(BCrypt::Password) })

    def password
      meta = { required: false, default: -> { BCrypt::Password.create(password) } }
      define_attribute(:encrypted_password, :string, **meta)

      meta.merge!(exclude_for_storage: true, default: -> { BCrypt::Password.new(encrypted_password) })
      define_attribute(:password, :password, **meta)

      :password
    end
  end
end
