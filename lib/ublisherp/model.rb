class Ublisherp::Model < OpenStruct
  include Ublisherp

  class RecordNotFound < StandardError; end

  def self.published_type(name=nil)
    if name
      @published_type = name
      @@published_types ||= {}
      @@published_types[@published_type] = self
    end
    @published_type || self.name.underscore.to_sym
  end

  def self.published_types
    @@published_types ||= {}
  end

  def self.find(id)
    data = Ublisherp.redis.get RedisKeys.key_for(self, id: id) 
    if data
      deserialize(data)
    else
      raise RecordNotFound, "#{self.name} not found with id #{id.inspect}"
    end
  end

  def self.deserialize(data)
    ruby_data = Ublisherp::Serializer.load(data)
    raise "Only one object should be in serialized blob" if ruby_data.size != 1

    type_name = ruby_data.keys.first
    model_class =
      published_types[type_name.to_sym] || type_name.to_s.camelize.constantize

    object_attrs = ruby_data.values.first
    object_attrs.keys.grep(/_(at|on)\z/).each do |key|
      object_attrs[key] = Time.parse(object_attrs[key])
    end

    model_class.new(object_attrs)
  end

  def self.all(**options)
    get_sorted_set RedisKeys.key_for_all(self), **options
  end

  def inspect
    "<#{self.class.name} id='#{id}'>"
  end

  def stream(name: :all, **options)
    key = RedisKeys.key_for_stream_of(self.class, name, id: id)
    self.class.get_sorted_set(key, **options)
  end


  def self.get_sorted_set(key, reverse: true, min: '-inf', max: '+inf', limit_count: 25)
    obj_keys = if reverse
                 Ublisherp.redis.zrevrangebyscore(key, max, min,
                                                  limit: [0, limit_count])
               else
                 Ublisherp.redis.zrangebyscore(key, min, max,
                                               limit: [0, limit_count])
               end
    if obj_keys.present?
      Ublisherp.redis.mget(*obj_keys).tap do |objs|
        objs.map! { |obj_json| deserialize(obj_json) }
      end
    else
      []
    end
  end

  def as_json(opts={})
    to_h
  end

  alias :attributes :to_h
end
