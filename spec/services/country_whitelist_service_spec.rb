require 'rails_helper'

RSpec.describe CountryWhitelistService, type: :service do
  before do
    described_class.clear_whitelist
  end

  after do
    described_class.clear_whitelist
  end

  describe '.add_countries' do
    it 'adds countries to the whitelist' do
      described_class.add_countries('US', 'CA', 'GB')
      
      expect(described_class.country_whitelisted?('US')).to be true
      expect(described_class.country_whitelisted?('CA')).to be true
      expect(described_class.country_whitelisted?('GB')).to be true
    end

    it 'handles lowercase country codes' do
      described_class.add_countries('us', 'ca')
      
      expect(described_class.country_whitelisted?('US')).to be true
      expect(described_class.country_whitelisted?('us')).to be true
    end
  end

  describe '.remove_countries' do
    it 'removes countries from the whitelist' do
      described_class.add_countries('US', 'CA', 'GB')
      described_class.remove_countries('CA')
      
      expect(described_class.country_whitelisted?('US')).to be true
      expect(described_class.country_whitelisted?('CA')).to be false
      expect(described_class.country_whitelisted?('GB')).to be true
    end
  end

  describe '.country_whitelisted?' do
    before do
      described_class.add_countries('US', 'CA')
    end

    it 'returns true for whitelisted countries' do
      expect(described_class.country_whitelisted?('US')).to be true
      expect(described_class.country_whitelisted?('us')).to be true
    end

    it 'returns false for non-whitelisted countries' do
      expect(described_class.country_whitelisted?('CN')).to be false
      expect(described_class.country_whitelisted?('RU')).to be false
    end

    it 'returns false for blank countries' do
      expect(described_class.country_whitelisted?(nil)).to be false
      expect(described_class.country_whitelisted?('')).to be false
      expect(described_class.country_whitelisted?('  ')).to be false
    end
  end

  describe '.whitelisted_countries' do
    it 'returns all whitelisted countries' do
      described_class.add_countries('US', 'CA', 'GB')
      countries = described_class.whitelisted_countries
      
      expect(countries).to contain_exactly('US', 'CA', 'GB')
    end

    it 'returns empty array when no countries are whitelisted' do
      expect(described_class.whitelisted_countries).to eq([])
    end
  end

  describe '.initialize_default_whitelist' do
    it 'adds default countries to the whitelist' do
      described_class.initialize_default_whitelist
      
      expect(described_class.country_whitelisted?('US')).to be true
      expect(described_class.country_whitelisted?('CA')).to be true
      expect(described_class.country_whitelisted?('GB')).to be true
      expect(described_class.whitelist_size).to eq(CountryWhitelistService::DEFAULT_COUNTRIES.size)
    end
  end

  describe '.whitelist_size' do
    it 'returns the correct size' do
      expect(described_class.whitelist_size).to eq(0)
      
      described_class.add_countries('US', 'CA')
      expect(described_class.whitelist_size).to eq(2)
    end
  end
end