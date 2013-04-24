module Ublisherp::RedisKeys

  def self.key_for(obj, id: nil)
    if !id # We are working out the key from an instance of an object
      raise(ArgumentError, "Object doesn't have an id yet") if obj.id.blank?
      id = obj.id
      klass = obj.class.name
    else
      klass = obj.model_name
    end

    "#{klass}:#{id}"
  end

  def self.key_for_all(obj)
    "#{obj.class.name}:all"
  end

  def self.key_for_stream_of(obj, name)
    "#{key_for(obj)}:streams:#{name}"
  end

  def self.key_for_streams_set(obj)
    "#{key_for(obj)}:in_streams"
  end

  def self.gone
    "gone"
  end

end
