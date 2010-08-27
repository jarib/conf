class Conf

  def self.configs
    @configs ||= {}
  end

  def self.define(name, parent = nil, &blk)
    parent = parent && get(parent)
    conf = configs[name] ||= Configuration.new(parent)

    conf.instance_eval(&blk)
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
      k = [@current_nesting, key].flatten.compact.join "."
      k
    end

    def freeze
      @parent && @parent.freeze
      super
    end

    def method_missing(meth, *args, &blk)
      m = meth.to_s

      if m =~ /^(\w+)=/ || args.size == 1
        raise "can't modify frozen config" if frozen?
        key = $1 || m
        self[key] = args.first
      elsif blk
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
          self
        end
      end
    end
  end
end


