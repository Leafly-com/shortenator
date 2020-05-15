# frozen_string_literal: true

RSpec.describe Shortenator do
  let(:bitly_token) { 'BITLY_TOKEN' }
  let(:domains) { ['leafly.com'] }
  let(:remove_protocol) { false }
  let(:ignore_200_check) { false }

  before do
    Shortenator.configure do |config|
      config.bitly_token = bitly_token
      config.domains = domains
      config.remove_protocol = remove_protocol
      config.ignore_200_check = ignore_200_check
    end
  end

  after do
    Shortenator.reset
  end

  it 'has a version number' do
    expect(Shortenator::VERSION).not_to be nil
  end

  context '::search_and_shorten_links', :vcr do
    let(:original_text) { "text #{url}" }
    let(:url) { 'http://leafly.com' }

    subject { Shortenator.search_and_shorten_links(original_text) }

    it 'should link' do
      expect(subject).to eq('text https://leafly.info/1CVNybj')
    end

    context 'with unconfigured domain' do
      let(:url) { 'http://google.com' }

      it 'should not link' do
        expect(subject).to eq(original_text)
      end
    end

    context 'with urls that return a 404 response' do
      let(:url) { 'http://leafly.com/BAD_PATH' }

      it 'should not link' do
        expect(subject).to eq(original_text)
      end
    end

    context 'with remove_protocol configuration' do
      let(:remove_protocol) { true }

      it 'should remove protocol in shortened link' do
        expect(subject).to eq('text leafly.info/1CVNybj')
      end
    end

    context 'with ignore_200_check configuration' do
      let(:ignore_200_check) { true }
      let(:url) { 'https://leafly.com/404' }

      it 'should shorten link regardless' do
        expect(subject).to eq('text https://leafly.info/35ny2W6')
      end
    end
  end

  end
end
