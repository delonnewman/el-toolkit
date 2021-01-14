module El
  class Form
    INPUT_TYPES = {
      text:      :text,
      number:    :number,
      email:     :email,
      password:  :password,
      phone:     :tel,
      telephone: :tel,
      checkbox:  :checkbox,
      radio:     :radio,
      color:     :color,
      date:      :date,
      datetime:  :"datetime-local",
      time:      :time,
      month:     :month,
      week:      :week,
      file:      :file,
      range:     :range,
      search:    :search,
      url:       :url
    }.freeze

    class << self
      def input(name, **options)
        @fields ||= {}
        @fields[name] = options
        name
      end

      INPUT_TYPES.each do |name, type|
        define_method name do |name, **options|
          input(name, options.merge(type: type))
        end
      end

      def textarea(name, options)
        @fields ||= {}
        @fields[name] = options.merge(type: :textarea)
        name
      end
    end
  end
end
