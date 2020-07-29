# frozen_string_literal: true

RSpec.describe Shortenator do
  let(:bitly_token) { 'BITLY_TOKEN' }
  let(:domains) { ['leafly.com'] }
  let(:remove_protocol) { false }
  let(:ignore_200_check) { false }
  let(:retry_amount) { 1 }
  let(:localhost_replacement) { 'example.com' }
  let(:default_tags) { [] }
  let(:bitly_group_guid) { nil }
  let(:caching_model) { nil }

  before do
    Shortenator.configure do |config|
      config.bitly_token = bitly_token
      config.domains = domains
      config.remove_protocol = remove_protocol
      config.ignore_200_check = ignore_200_check
      config.retry_amount = retry_amount
      config.localhost_replacement = localhost_replacement
      config.default_tags = default_tags
      config.bitly_group_guid = bitly_group_guid
      config.caching_model = caching_model
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
    let(:additonal_args) { [] }

    subject { Shortenator.search_and_shorten_links(original_text, *additonal_args) }

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

    context 'with bitly_group_guid' do
      let(:url) { 'https://www.leafly.com/strains' }
      let(:default_short_url) { 'https://leafly.info/2ZPPyQD' }
      let(:default_short_text) { "text #{default_short_url}" }
      let(:custom_bitly_group_guid) { 'Be1ojaikusR' }

      it 'will use default bitly group_guid when not set' do
        expect(subject).to eq(default_short_text)
        expect(get_bitlink_details('leafly.info/2ZPPyQD')['references']['group']).to end_with('B01103Ajtve')
      end

      context 'when provided a different group guid' do
        let(:bitly_group_guid) { custom_bitly_group_guid }

        it 'assigns new link id and new custom bitly_group_guid' do
          expect(subject).to_not eq(default_short_text)
          expect(subject).to eq('text https://leafly.info/2CgYGWs')
          expect(get_bitlink_details('leafly.info/2CgYGWs')['references']['group']).to end_with(custom_bitly_group_guid)
        end
      end

      context 'can be set at runtime' do
        let(:additonal_args) { [bitly_group_guid: custom_bitly_group_guid] }

        it 'shortens link with new bitly_group_guid' do
          expect(subject).to eq('text https://leafly.info/2CgYGWs')
          expect(get_bitlink_details('leafly.info/2CgYGWs')['references']['group']).to end_with(custom_bitly_group_guid)
        end
      end

      context 'with caching_model set' do
        before do
          # allow(BitlyLinks).to(receive(:find).with(long_url: url).and_return(["https://leafly.info/2CgYGWs"]))
        end

        context 'saves a link to reuse later' do
          let(:caching_model) { BitlyLinks }

          it 'makes a bitly call and saves the link' do
            # Given
            allow(BitlyLinks).to(receive(:find_by).with(long_link: url).and_return([]))
            allow(BitlyLinks).to(receive(:create).with(long_link: url, short_link: 'https://leafly.info/2CgYGWs'))

            # Expect
            # A call to find an existing link
            expect(caching_model).to(receive(:find_by).with(long_link: url).and_return([]))
            # a call to bitly
            mock_object = instance_double(Bitly::API::Bitlink, link: 'https://leafly.info/2CgYGWs')
            expect_any_instance_of(Bitly::API::Client).to(receive(:create_bitlink).and_return(mock_object))
            # a call to cache
            expect(caching_model).to(receive(:create).with(long_link: url, short_link: 'https://leafly.info/2CgYGWs'))

            expect(subject).to eq('text https://leafly.info/2CgYGWs')
          end

          it 'since the link is saved, no bitly call made' do
            returned_data = BitlyLinks.new
            returned_data.long_link = url
            returned_data.short_link = 'https://leafly.info/2CgYGWs'
            # Given
            allow(BitlyLinks).to(receive(:find_by).with(long_link: url).and_return([returned_data]))

            # Expect
            # A call to find an existing link
            expect(caching_model).to(receive(:find_by).with(long_link: url).and_return([returned_data]))

            # no call to bitly
            # call to find expected w/result
            expect(subject).to eq('text https://leafly.info/2CgYGWs')
          end

          it 'will log warning when more than one shortened link' do
            returned_data = BitlyLinks.new
            returned_data.long_link = url
            returned_data.short_link = 'https://leafly.info/2CgYGWs'
            # Given
            allow(BitlyLinks).to(receive(:find_by).with(long_link: url).and_return([returned_data, returned_data]))

            # Expect
            # a call to bitly
            expect(subject).to eq('text https://leafly.info/2CgYGWs')
          end
        end
        context 'with model with incorrect attributes' do
          let(:caching_model) { Shlinks }

          it 'throws an error' do
            # expect(subject).to eq('text https://leafly.info/2CgYGWs')
            expect { subject }.to raise_error('Model is not valid, it must be an object (perferably ActiveRecord) with a `long_link` and `short_link`')
          end
        end
        context 'with model without correct methods' do
          let(:caching_model) { LilLinks }

          it 'throws an error' do
            expect { subject }.to raise_error('Model is not valid, it must be an object (perferably ActiveRecord) with `find_by(long_link:)` and `create(long_link:, short_link:)` methods')
          end
        end
      end
    end
  end
end

def get_bitlink_details(bitlink)
  Shortenator.bitly_client.bitlink(bitlink: bitlink).response.body
end

class BitlyLinks
  attr_accessor \
    :long_link,
    :short_link

  def find_by(*args); end

  def create(*args); end
end

class Shlinks
  attr_accessor \
    :wumbo_link,
    :mini_link

  def find_by(*args); end

  def create(*args); end
end

class LilLinks
  attr_accessor \
    :long_link,
    :short_link
end
