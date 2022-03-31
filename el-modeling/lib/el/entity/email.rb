module El
  module Entity::Email
    EMAIL_REGEXP = %r{\A[a-zA-Z0-9!#$%&'*+/=?\^_`{|}~\-]+(?:\.[a-zA-Z0-9!#$%&'*+/=?\^_`{|}~\-]+)*@(?:[a-zA-Z0-9](?:[a-zA-Z0-9\-]*[a-zA-Z0-9])?\.)+[a-zA-Z0-9](?:[a-zA-Z0-9\-]*[a-zA-Z0-9])?$\z}.freeze
    El::Types.define_alias :email, El::Types::RegExpType[EMAIL_REGEXP]

    def email(name = :email, **options)
      define_attribute(name, :email, **options)
    end
  end
end
