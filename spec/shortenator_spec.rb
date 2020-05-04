# frozen_string_literal: true

RSpec.describe Shortenator do
  before do
    Shortenator.configure do |config|
      config.domains = ['leafly.com']
      config.bitly_token = 'BITLY_TOKEN'
    end
  end

  after do
    Shortenator.reset
  end

  it 'has a version number' do
    expect(Shortenator::VERSION).not_to be nil
  end

  it 'does not shorten domains not configured' do
    expect(Shortenator.search_and_shorten_links('text http://google.com')).to eq('text http://google.com')
  end

  it 'does not shorten domains that applies but return a 404', :vcr do
    expect(Shortenator.search_and_shorten_links('text http://leafly.com/BAD_PATH')).to eq('text http://leafly.com/BAD_PATH')
  end

  it 'shortens valid links that applies', :vcr do
    expect(Shortenator.search_and_shorten_links('text http://leafly.com')).to eq('text https://leafly.info/1CVNybj')
  end

  it 'can shorten links to have no protcol', :vcr do
    Shortenator.config.remove_protocol = true

    expect(Shortenator.search_and_shorten_links('text http://leafly.com')).to eq('text leafly.info/1CVNybj')
  end
end
