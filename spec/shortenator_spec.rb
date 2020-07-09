# frozen_string_literal: true

RSpec.describe Shortenator do
  let(:bitly_token) { 'BITLY_TOKEN' }
  let(:domains) { ['leafly.com'] }
  let(:remove_protocol) { false }
  let(:ignore_200_check) { false }
  let(:retry_amount) { 1 }
  let(:localhost_replacement) { 'example.com' }
  let(:tags) { [] }
  let(:group_guid) { nil }

  before do
    Shortenator.configure do |config|
      config.bitly_token = bitly_token
      config.domains = domains
      config.remove_protocol = remove_protocol
      config.ignore_200_check = ignore_200_check
      config.retry_amount = retry_amount
      config.localhost_replacement = localhost_replacement
      config.tags =  tags
      config.group_guid = group_guid
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
      let(:tags) { ['tag_name'] }

      it 'should be associated to link' do
        expect(get_bitlink_details('leafly.info/1CVNyb')['tags']).to eq(tags)
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
      let(:tags) { ['tag_name'] }
      let(:more_tags) { ['more_tags'] }
      let(:additonal_args) { [additional_tags: more_tags] }
      let(:url) { 'https://leafly.com/finder' }

      it 'saves link with addtional tags with config' do
        subject

        # NOTE: It took some time for the tags to save between the post and retrieval
        expect(get_bitlink_details('leafly.info/2Z8NtQw')['tags']).to eq(tags + more_tags)
      end
    end

    context 'with new tags' do
      let(:tags) { ['tag_name'] }
      let(:new_tags) { ['newer_tag'] }
      let(:additonal_args) { [tags: new_tags] }
      let(:url) { 'https://leafly.com/strains' }

      it 'disregards config tags, sets new one' do
        subject

        # NOTE: It took some time for the tags to save between the post and retrieval
        expect(get_bitlink_details('leafly.info/3gFjOV2')['tags']).to eq(new_tags)
      end
    end

    context 'with group_guid' do
      let(:url) { 'https://www.leafly.com/strains' }
      let(:default_short_url) { 'https://leafly.info/2ZPPyQD' }
      let(:default_short_text) { "text #{default_short_url}" }
      let(:custom_group_guid) { 'Be1ojaikusR' }

      it 'will use default group_guid when not set' do
        expect(subject).to eq(default_short_text)
        expect(get_bitlink_details('leafly.info/2ZPPyQD')['references']['group']).to end_with('B01103Ajtve')
      end

      context 'when provided a different group guid' do
        let(:group_guid) { custom_group_guid }

        it 'assigns new link id and new custom group_guid' do
          expect(subject).to_not eq(default_short_text)
          expect(subject).to eq('text https://leafly.info/2CgYGWs')
          expect(get_bitlink_details('leafly.info/2CgYGWs')['references']['group']).to end_with(custom_group_guid)
        end
      end

      context 'can be set at runtime' do
        let(:additonal_args) { [group_guid: custom_group_guid] }

        it 'shortens link with new group_guid' do
          expect(subject).to eq('text https://leafly.info/2CgYGWs')
          expect(get_bitlink_details('leafly.info/2CgYGWs')['references']['group']).to end_with(custom_group_guid)
        end
      end
    end
  end
end

def get_bitlink_details(bitlink)
  Shortenator.bitly_client.bitlink(bitlink: bitlink).response.body
end
