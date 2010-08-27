class Conf

  class InvalidKeyError < StandardError
  end
  
  class InvalidStateError < StandardError
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
    conf.lock!
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

      @parent          = parent
      @data            = {}
      @current_nesting = []
      @locked          = false
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

      @data.each do |key, value|
        result[key] = value if key =~ /^#{Regexp.escape start_key}/
      end

      result
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
        check_lock
        key = $1 || m
        self[key] = args.first
      elsif blk
        check_lock
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
          validate_nesting if locked?
          self
        end
      end
    end

    def validate_nesting
      current = expand_key(nil)
      match_proc = Proc.new { |key,_| key =~ /^#{Regexp.escape current}/ }

      unless @data.any?(&match_proc) || (@parent && @parent.data.any?(&match_proc))
        @current_nesting.clear
        raise InvalidKeyError, "no such key: #{current.inspect}"
      end
    end

    def check_lock
      if locked?
        @current_nesting.clear
        raise InvalidStateError, "config is locked"
      end
    end
  end
end


