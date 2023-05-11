# frozen_string_literal: true

require_relative '../../lib/el/trait'

describe El::Trait do
  subject(:trait) do
    Module.new.tap do |mod|
      mod.module_eval do
        extend El::Trait
        requires :call, 'call me'
        def to_proc
          proc do |*args|
            call(*args)
          end
        end
      end
    end
  end

  it 'provides a set of methods that implement behavior' do
    expect(trait.instance_methods).to eq [:to_proc]
  end

  it 'raises an exception if a class does not have a required method' do
    expect { Class.new.include(trait) }.to raise_error El::Trait::MissingMethodError
  end

  it 'will not raise an exception if all the required methods are present' do
    klass = Class.new
    klass.define_method(:call) { 1 }

    expect { klass.include(trait) }.not_to raise_error
  end

  it 'will not raise and exception if the required methods are defined within a `uses` block' do
    expect { Class.new.uses(trait) { define_method(:call) { 1 } } }.not_to raise_error
  end

  it 'collects meta data on required methods' do
    expect(trait.metadata).to match(methods: { call: { doc: 'call me', required: true } })
  end

  describe '#required_methods' do
    it 'returns an array of method names' do
      expect(trait.required_methods).to eq %i[call]
    end
  end

  context 'when one trait composes another' do
    it 'will add the requirements of the composed trait to itself' do
      trait2 = Module.new
      trait2.extend(El::Trait)
      trait2.requires(:some_other_method)
      required = trait2.required_methods.dup

      trait2.include(trait)

      expect(trait2.required_methods).to eq required + trait.required_methods
    end
  end
end
