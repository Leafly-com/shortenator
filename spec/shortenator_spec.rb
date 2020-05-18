# frozen_string_literal: true

RSpec.describe Shortenator do
  let(:bitly_token) { 'BITLY_TOKEN' }
  let(:domains) { ['leafly.com'] }
  let(:remove_protocol) { false }
  let(:ignore_200_check) { false }
  let(:retry_amount) { 1 }
  let(:localhost_replacement) { 'example.com' }

  before do
    Shortenator.configure do |config|
      config.bitly_token = bitly_token
      config.domains = domains
      config.remove_protocol = remove_protocol
      config.ignore_200_check = ignore_200_check
      config.retry_amount = retry_amount
      config.localhost_replacement = localhost_replacement
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

    context 'with retry_amount configuration' do
      let(:retry_amount) { 3 }
      let(:url) { 'http://leafly.com/' }

      it 'should shorten link after 3 attempts' do
        expect(subject).to eq('text https://leafly.info/1CVNybj')
      end
    end

    context 'with incorrect retry_amount configuration' do
      let(:retry_amount) { -1 }
      let(:url) { 'http://leafly.com/' }
      let(:error_msg) { "retry amount must be a number equal or greater than 0, saw #{retry_amount}" }

      it 'should fail immediately' do
        expect { subject }.to raise_error(error_msg)
      end
    end

    context 'when given localhost' do
      let(:localhost_replacement) { 'example-two.com' }
      let(:domains) { ['localhost'] }
      let(:ignore_200_check) { true }
      let(:url) { 'https://localhost:3000/site/path' }

      it 'rewrites to example-two.com' do
        expect(subject).to eq('text https://leafly.info/3bIC5xY')
      end
    end
  end
end
