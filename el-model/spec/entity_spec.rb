require 'spec_helper'
include Drn::Framework

class EntityBasic < Entity
end

class EntitySingle < Entity
  has :name
end

class EntityTyped < Entity
  has :number, Integer
end

RSpec.describe Entity do
  describe '.valid?' do
    it 'should return false if given an empty value' do
      expect(EntityBasic.valid?({})).to be false
    end

    it 'should return true if entity has no attributes and the value is not empty' do
      expect(EntityBasic.valid?(test: 1)).to be true
    end

    it 'should return false if the entity has attributes and the value is not valid' do
      expect(EntitySingle.valid?(test: 1)).to be_falsy
    end

    it 'should return true if the entity has attributes and the value is valid' do
      expect(EntitySingle.valid?(name: 'Tester')).to be true
    end

    it 'should accept an entity instance with the right shape' do
      expect(EntitySingle.valid?(EntitySingle[name: 'Tester'])).to be true
      expect(EntityTyped.valid?(EntityTyped[number: 1])).to be true
    end
  end

  describe '.errors' do
    it 'should return an empty hash if there are no errors' do
      expect(EntityBasic.errors({})).to be_empty
      expect(EntityBasic.errors(test: 1)).to be_empty
      expect(EntitySingle.errors(name: 'testing')).to be_empty
      expect(EntityTyped.errors(number: 1)).to be_empty
    end

    it 'should return a hash of errors if the given data is not valid' do
      errors = EntitySingle.errors(test: 1)
      expect(errors).not_to be_empty
      expect(errors[:name]).not_to be_empty
      expect(errors[:name][0]).to eq 'Name is required'

      errors = EntityTyped.errors(number: 'test')
      expect(errors).not_to be_empty
      expect(errors[:number]).not_to be_empty
      expect(errors[:number][0]).to eq 'Number is not valid'
    end
  end
end
