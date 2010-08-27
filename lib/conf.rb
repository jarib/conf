class Conf

  class InvalidKeyError < StandardError
  end

  class InvalidStateError < StandardError
  end

  module ConfigValue
    def self.create(root, key, obj = Object.new)
      return obj if obj == true || obj == false
      
      begin
        obj.extend(self)
        obj.__setup__(root, key)
      rescue TypeError
        # can't extend obj
      end

      obj
    end

    def __setup__(root, key)
      @__root__ = root
      @__key__  = key

      self
    end

    def method_missing(meth, *args, &blk)
      m = meth.to_s
      if m =~ /^(\w+)=/ || args.size == 1
        @__root__.check_lock
        key = [@__key__, $1 || m].compact.join(".")
        @__root__[key] = ConfigValue.create(@__root__, key, args.first)
      else
        key = [@__key__, m].compact.join(".")

        obj = @__root__.data[key]

        if obj.nil?
          if @__root__.locked?
            obj = @__root__.fetch(key) { raise Conf::InvalidKeyError, key }
          else
            obj = @__root__.data[key] = ConfigValue.create(@__root__, key)
          end
        end

        if blk
          @__root__.check_lock
          obj.instance_eval(&blk)
        end

        obj
      end
    end
  end # ConfigValue

  def self.configs
    @configs ||= {}
  end

  def self.define(name, parent = nil, &blk)
    case parent
    when String, Symbol
      parent = get(parent)
    when Configuration, nil
      # ok
    else
      raise TypeError,
      "expected String, Symbol, Configuration or nil, got #{parent.inspect}:#{parent.class}"
    end

    conf = configs[name] ||= Configuration.new(parent)
    conf.instance_eval(&blk)

    conf.lock!
    conf
  end

  def self.get(name)
    configs[name] or raise ArgumentError, "no config named #{name.inspect}"
  end

  class Configuration
    include ConfigValue

    def initialize(parent = nil)
      if parent and not parent.kind_of? self.class
        raise TypeError, "expected #{self.class}, got #{parent.inspect}:#{parent.class}"
      end

      @parent   = parent
      @data     = {}
      @locked   = false
      @__root__ = self
    end

    def key?(key)
      @data.key?(key) || (@parent && @parent.key?(key))
    end

    def lock!
      @locked = true
    end

    def unlock!
      @locked = false
    end

    def unlocked(&blk)
      unlock!
      yield
      lock!
    end

    def check_lock
      if locked?
        raise InvalidStateError, "config is locked #{@data.keys.inspect}"
      end
    end

    def edit(&blk)
      edit!
      instance_eval(&blk)
      done!
    end

    def locked?
      @locked
    end

    def section(start_key)
      result = @parent ? @parent.section(start_key) : {}
      rx = /^#{Regexp.escape(start_key).gsub("\\*", ".+?")}/

      @data.each do |key, value|
        result[key] = value if key =~ rx and not value.instance_of? Object
      end

      result
    end

    def data() @data end

    def fetch(key, &blk)
      val = self[key]
      if val.nil?
        @data[key] = yield(key)
      else
        val
      end
    end


    def [](key)
      val = @data[key]

      if val.nil?
        @parent && @parent[key]
      else
        val
      end
    end

    def []=(key, value)
      @data[key] = value
    end
  end

end
