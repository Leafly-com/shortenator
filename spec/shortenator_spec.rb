# frozen_string_literal: true

RSpec.describe Shortenator do
  let(:bitly_token) { 'BITLY_TOKEN' }
  let(:domains) { ['leafly.com'] }
  let(:remove_protocol) { false }
  let(:ignore_200_check) { false }
  let(:retry_amount) { 1 }
  let(:localhost_replacement) { 'example.com' }
  let(:default_tags) { [] }

  before do
    Shortenator.configure do |config|
      config.bitly_token = bitly_token
      config.domains = domains
      config.remove_protocol = remove_protocol
      config.ignore_200_check = ignore_200_check
      config.retry_amount = retry_amount
      config.localhost_replacement = localhost_replacement
      config.default_tags = default_tags
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
    let(:original_args) { [original_text] }
    let(:additonal_args) { [] }

    subject { Shortenator.search_and_shorten_links(*original_args, *additonal_args) }

    it 'should link' do
      expect(subject).to eq('text https://leafly.info/1CVNybj')
    end

    context 'with tags' do
      let(:default_tags) { ['tag_name'] }

      it 'should be associated to link' do
        expect(get_bitlink_details('leafly.info/1CVNyb')['tags']).to eq(default_tags)
      end
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

    context 'with additional tags' do
      let(:default_tags) { ['tag_name'] }
      let(:more_tags) { ['more_tags'] }
      let(:additonal_args) { [additional_tags: more_tags] }
      let(:url) { 'https://leafly.com/finder' }

      it 'saves link with addtional tags with config' do
        subject

        # NOTE: It took some time for the tags to save between the post and retrieval
        expect(get_bitlink_details('leafly.info/2Z8NtQw')['tags']).to eq(default_tags + more_tags)
      end
    end

    context 'with new tags' do
      let(:default_tags) { ['tag_name'] }
      let(:new_tags) { ['newer_tag'] }
      let(:additonal_args) { [tags: new_tags] }
      let(:url) { 'https://leafly.com/strains' }

      it 'disregards config tags, sets new one' do
        subject

        # NOTE: It took some time for the tags to save between the post and retrieval
        expect(get_bitlink_details('leafly.info/3gFjOV2')['tags']).to eq(new_tags)
      end
    end
  end
end

def get_bitlink_details(bitlink)
  Shortenator.bitly_client.bitlink(bitlink: bitlink).response.body
end
