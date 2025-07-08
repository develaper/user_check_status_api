require 'rails_helper'

RSpec.describe ApplicationRecord, type: :model do
  it "should be a class" do
    expect(ApplicationRecord).to be_a(Class)
  end
end
