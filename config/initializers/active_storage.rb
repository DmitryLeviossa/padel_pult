ActiveSupport.on_load(:active_storage_blob) do
  class << self
    prepend(Module.new do
      def generate_unique_secure_token(length: MINIMUM_TOKEN_LENGTH)
        "#{Rails.env}/#{super}"
      end
    end)
  end
end
