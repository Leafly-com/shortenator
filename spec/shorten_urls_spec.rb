# frozen_string_literal: true

RSpec.describe ShortenUrls do
  it 'has a version number' do
    expect(ShortenUrls::VERSION).not_to be nil
  end

  it 'does something useful' do
    ShortenUrls.configure do |config|
      config.domains = ['leafly.com']
      config.bitly_token = 'BITLY_TOKEN'
    end

    VCR.use_cassette RSpec.current_example.full_description do
      expect(ShortenUrls.shorten_url('text http://leafly.com')).to eq('text https://leafly.info/1CVNybj')
    end
  end
end
