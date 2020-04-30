# frozen_string_literal: true

RSpec.describe ShortenUrls do
  before do
    ShortenUrls.configure do |config|
      config.domains = ['leafly.com']
      config.bitly_token = 'BITLY_TOKEN'
    end
  end

  it 'has a version number' do
    expect(ShortenUrls::VERSION).not_to be nil
  end

  it 'does not shorten domains not configured' do
    expect(ShortenUrls.shorten_url('text http://google.com')).to eq('text http://google.com')
  end

  it 'does not shorten domains that applies but return a 404' do
    VCR.use_cassette RSpec.current_example.full_description do
      expect(ShortenUrls.shorten_url('text http://leafly.com/BAD_PATH')).to eq('text http://leafly.com/BAD_PATH')
    end
  end

  it 'shortens valid links that applies' do
    VCR.use_cassette RSpec.current_example.full_description do
      expect(ShortenUrls.shorten_url('text http://leafly.com')).to eq('text https://leafly.info/1CVNybj')
    end
  end
end
