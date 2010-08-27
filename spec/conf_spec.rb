require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Conf" do
  before { Conf.configs.clear }

  it "should set a single value" do
    conf = Conf.define(:tmp) { bar "baz" }
    conf.bar.should == "baz"
  end

  it "can be defined with a String parent" do
    parent = Conf.define('parent') {}
    lambda { Conf.define('child', 'parent') {}  }.should_not raise_error
  end

  it "can be defined with a Symbol parent" do
    parent = Conf.define(:parent) {}
    lambda { Conf.define(:child, :parent) {}  }.should_not raise_error
  end

  it "can be defined with a Configuration parent" do
    parent = Conf.define(:parent) {}
    lambda { Conf.define(:child, :parent) {}  }.should_not raise_error
  end

  it "can be defined with a Configuration parent" do
    parent = Conf.define(:parent) {}
    lambda { Conf.define(:child, parent) {}  }.should_not raise_error
  end

  it "raises a TypeError if parent is not a known type" do
    lambda { Conf.define(:foo, {}) {} }.should raise_error(TypeError)
  end

  it "should set a nested properties-style value" do
    conf = Conf.define(:tmp) { bar.baz :boo }
    conf.bar.baz.should == :boo
  end

  it "should set a value with nested blocks" do
    conf = Conf.define(:tmp) do
      nested { block { also { works true }}}
    end

    conf.nested.block.also.works.should be_true
  end

  it "should inherit properties from parent" do
    parent = Conf.define(:parent)       { foo.bar.baz = false }
    child = Conf.define(:child, parent) { foo.bar.boo = true }

    child.foo.bar.baz.should be_false
    child.foo.bar.boo.should be_true
  end

  it "should override parent properties" do
    parent = Conf.define(:parent)       { foo.bar.baz = true }
    child = Conf.define(:child, parent) { foo.bar.baz = false }

    parent.foo.bar.baz.should be_true
    child.foo.bar.baz.should be_false
  end

  it "should inherit nested blocks from parent" do
    parent = Conf.define(:parent)         { foo { bar { baz true }}}
    child  = Conf.define(:child, parent)  { foo { bar { boo false }}}

    child.foo.bar.baz.should be_true
    child.foo.bar.boo.should be_false
  end

  it "should override parent nested blocks" do
    parent = Conf.define(:parent)         { foo { bar { baz true }}}
    child  = Conf.define(:child, parent)  { foo { bar { baz false }}}

    parent.foo.bar.baz.should be_true
    child.foo.bar.baz.should be_false
  end

  it "cannot be changed after being defined" do
    conf = Conf.define(:tmp) { foo "bar" }
    conf.foo.should == "bar"
    lambda { conf.foo "baz" }.should raise_error(Conf::InvalidStateError)
  end

  it "raises a TypeError if parent is not nil or Configuration instance" do
    lambda { Conf::Configuration.new({}) }.should raise_error(TypeError)
  end

  it "raises an error if the key is not found" do
    conf = Conf.define(:tmp) { foo.bar.baz false }
    lambda { conf.bar }.should raise_error(Conf::InvalidKeyError)
  end

  it "can check if a key exists" do
    conf = Conf.define(:tmp) { foo.bar.baz false }
    conf.key?("foo.bar.baz").should be_true
    conf.key?("bar").should be_false
  end

  it "retrieves a section of the config as a hash" do
    Conf.define(:tmp) {
      foo.bar.baz 1
      foo.bar.boo 2
      foo.bla.baz 3
    }.section("foo.bar").should == {"foo.bar.baz" => 1, "foo.bar.boo" => 2}
  end

  it "handles wildcards in section() string" do
    Conf.define(:tmp) {
      foo.bar.baz 1
      foo.bar.boo 2
      foo.bla.baz 3
    }.section("foo.*.baz").should == {"foo.bar.baz" => 1, "foo.bla.baz" => 3}
  end

  it "merges parent data when fetching section" do
    parent = Conf.define(:parent) { foo.bar.baz 1 }
    child = Conf.define(:child, parent) { foo.bar.bah 2; }

    child.section("foo.bar").should == {"foo.bar.baz" => 1, "foo.bar.bah" => 2}
  end

end
