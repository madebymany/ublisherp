require 'securerandom'

module Ublisherp::Publishable
  extend ActiveSupport::Concern

  included do
    if self.respond_to?(:include_root_in_json=)
      self.include_root_in_json = true
    end
  end

  module ClassMethods
    def publish_associations(*assocs)
      @publish_associations ||= []
      @publish_associations.concat Array.new(assocs || [])
      @publish_associations
    end

    def publish_stream(name: :all, **options)
      @publish_streams ||= []

      @publish_streams << options.merge(name: name)
      @publish_streams.uniq!
    end

    def publish_streams; @publish_streams || []; end

    def published_type
      self.name.underscore.to_sym
    end
  end

  def publisher
    @publisher ||=
      begin
        "#{self.class.name}Publisher".constantize.new self
      rescue NameError
        Ublisherp::Publisher.new self
      end
  end

  def as_publishable(opts = {})
    as_json(opts)
  end

end

module Ublisherp::PublishableWithInstanceShortcuts
  extend ActiveSupport::Concern

  include Ublisherp::Publishable


  def publish!(**options)
    publisher.publish!(**options)
  end

  def unpublish!(**options)
    publisher.unpublish!(**options)
  end

end
