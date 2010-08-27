require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Conf" do
  before { Conf.configs.clear }

  it "should set a single value" do
    conf = Conf.define(:tmp) { bar "baz" }
    conf.bar.should == "baz"
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
    lambda { conf.foo "baz" }.should raise_error
  end

end
