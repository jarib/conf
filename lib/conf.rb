class Conf

  class InvalidKeyError < StandardError
  end

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
      raise TypeError, "expected String, Symbol, Configuration or nil, got #{parent.inspect}:#{parent.class}"
    end

    conf = configs[name] ||= Configuration.new(parent)

    conf.instance_eval(&blk)
    conf.freeze
    conf
  end

  def self.get(name)
    configs[name] or raise ArgumentError, "no config named #{name.inspect}"
  end

  class Configuration
    def initialize(parent = nil)
      if parent and not parent.kind_of? self.class
        raise TypeError, "expected #{self.class}, got #{parent.inspect}:#{parent.class}"
      end

      @parent = parent
      @data   = {}
      @current_nesting = []
    end

    def freeze
      @parent && @parent.freeze
      super
    end

    protected

    def data() @data end

    def [](key)
      k = expand_key(key)
      val = @data[k]
      val.nil? ? @parent && @parent[k] : val
    end

    def []=(key, value)
      @data[expand_key(key)] = value
      @current_nesting.clear
    end

    def expand_key(key)
      [@current_nesting, key].flatten.compact.join "."
    end

    def method_missing(meth, *args, &blk)
      m = meth.to_s

      if m =~ /^(\w+)=/ || args.size == 1
        check_frozen
        key = $1 || m
        self[key] = args.first
      elsif blk
        check_frozen
        @current_nesting << m
        instance_eval(&blk)
        @current_nesting.pop
      else
        obj = self[m]
        if obj != nil
          @current_nesting.clear
          obj
        else
          @current_nesting << m
          validate_nesting if frozen?
          self
        end
      end
    end

    def validate_nesting
      current = expand_key(nil)
      unless @data.any? { |key,_| key.start_with?(current)} || (@parent && @parent.data.any? { |key,_| key.start_with?(current)})
        @current_nesting.clear
        raise InvalidKeyError, "no such key: #{current.inspect}"
      end
    end

    def check_frozen
      if frozen?
        @current_nesting.clear
        raise "can't modify frozen config"
      end
    end
  end
end


