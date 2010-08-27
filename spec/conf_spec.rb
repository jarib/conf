require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Conf" do
  before { Conf.configs.clear }

  # TODO: real specs
  it "works like the readme" do
    Conf.define(:parent) do
      properties.like.syntax = :nice

      single "pair"

      nested {
        ruby {
          blocks true
        }
      }
    end

    Conf.define(:child, :parent) do
      nested {
        ruby {
          blocks false
        }
      }
    end

    c = Conf.get(:child)

    pp c

    c.nested.ruby.blocks.should be_false
    c.single.should == "pair"
    c.properties.like.syntax.should == :nice

    c.yet.another :value
    c.yet.another.should == :value

    c.freeze
    lambda {
      c.yet.another :changed
    }.should raise_error(RuntimeError, "can't modify frozen config")
  end

  it "should set a single value" do
    Conf.define(:foo) { bar "baz" }.bar.should == "baz"
  end

  it "should set a nested properties-style value" do
    Conf.define(:foo) { bar.baz :boo }.bar.baz.should == :boo
  end
end
