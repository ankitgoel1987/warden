# coding: UTF-8

require "spec_helper"
require "warden/protocol"

describe Warden::Protocol::WrappedRequest do
  it "should respond to #request" do
    w = Warden::Protocol::WrappedRequest.new
    w.type = Warden::Protocol::Type::Ping
    w.payload = Warden::Protocol::PingRequest.new.encode
    w.should be_valid

    w.request.should be_a(Warden::Protocol::PingRequest)
  end
end

describe Warden::Protocol::WrappedResponse do
  it "should respond to #response" do
    w = Warden::Protocol::WrappedResponse.new
    w.type = Warden::Protocol::Type::Ping
    w.payload = Warden::Protocol::PingResponse.new.encode
    w.should be_valid

    w.response.should be_a(Warden::Protocol::PingResponse)
  end
end

describe Warden::Protocol do
  before :all do
    module Test
      A = 1
      B = 2
    end
  end

  describe "#protocol_type_to_str" do
    it "should return string representation of constants in a module" do
      described_class.protocol_type_to_str(Test).should == "A, B"
    end

    it "should return string representation of symbol" do
      described_class.protocol_type_to_str(:test).should == "test"
    end

    it "should return nil for invalid parameter" do
      described_class.protocol_type_to_str(123).should be_nil
    end
  end

  describe "#to_ruby_type" do
    it "should use the type converter if is defined" do
      Warden::Protocol::TypeConverter.should_receive("[]").once.
        with(:uint32).and_return(lambda { |arg| Integer(arg) } )

      described_class.to_ruby_type("123", :uint32).should == 123
    end

    it "should return value of constant defined in the module" do
      Warden::Protocol::TypeConverter.should_receive("[]").once.
        with(Test).and_return(nil)

      described_class.to_ruby_type("A", Test).should == 1
    end

    it "should raise an error if a constant is not defined in a module" do
      Warden::Protocol::TypeConverter.should_receive("[]").once.
        with(Test).and_return(nil)

      expect {
        described_class.to_ruby_type("D", Test)
      }.to raise_error { |error|
        error.should be_an_instance_of TypeError
        error.message.should == "The constant: 'D' is not defined in the module: 'Test'."
      }
    end

    it "should raise an error if protocol type is not a module and no type converter is defined" do
      Warden::Protocol::TypeConverter.should_receive("[]").once.
        with(:test).and_return(nil)

      expect {
        described_class.to_ruby_type("test", :test)
      }.to raise_error { |error|
        error.should be_an_instance_of TypeError
        error.message.should == "Non-existent protocol type passed: 'test'."
      }
    end
  end
end
