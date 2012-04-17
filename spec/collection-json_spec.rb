require 'spec_helper'
require 'collection-json'

describe CollectionJSON do
  describe :add_host do
    before :each do
      @href = '/friends'
    end

    context 'with COLLECTION_JSON_HOST set' do
      it 'returns full uri' do
        ENV['COLLECTION_JSON_HOST'] = EXAMPLE_HOST
        uri = CollectionJSON.add_host(@href)
        uri.should eq("http://localhost/friends")
      end
    end

    context 'without COLLECTION_JSON_HOST set' do
      it 'returns partial uri' do
        ENV['COLLECTION_JSON_HOST'] = nil
        uri = CollectionJSON.add_host(@href)
        uri.should eq("/friends")
      end
    end
  end

  describe :generate_for do
    before :each do
      @friends = [
        {
          "id"        =>  "jdoe",
          "full-name" =>  "J. Doe",
          "email"     =>  "jdoe@example.org"
        },
        {
          "id"        =>  "msmith",
          "full-name" =>  "M. Smith",
          "email"     =>  "msmith@example.org"
        },
        {
          "id"        =>  "rwilliams",
          "full-name" =>  "R. Williams",
          "email"     =>  "rwilliams@example.org"
        }
      ]
    end

    it 'should generate an object with the attributes we expect' do
      response = CollectionJSON.generate_for('/friends/') do |builder|
        builder.add_link '/friends/rss', 'feed'
        @friends.each do |friend|
          builder.add_item("/friends/#{friend['id']}") do |item|
            item.add_data "full-name", friend["full-name"]
            item.add_data "email", friend["email"]
            item.add_link "/blogs/#{friend['id']}", "blog", "", "Blog"
            item.add_link "/blogs/#{friend['id']}", "avatar", "", "Avatar", "image"
          end
        end
        builder.add_query("/friends/search", "search", "Search") do |query|
          query.add_data "search"
        end
        builder.set_template do |template|
          template.add_data "full-name", "", "Full Name"
          template.add_data "email", "", "Email"
          template.add_data "blog", "", "Blog"
          template.add_data "avatar", "", "Avatar"
        end
      end

      response.href.should eq('/friends/')
      response.links.first.href.should eq("/friends/rss")
      response.items.length.should eq(3)
      response.items.first.data.length.should eq(2)
      response.items.first.links.length.should eq(2)
      response.items.first.href.class.should eq(String)
      response.template.data.length.should eq(4)
      response.queries.length.should eq(1)
      response.queries.first.href.should eq("/friends/search")
      response.queries.first.data.length.should eq(1)
      response.queries.first.data.first.name.should eq('search')
    end
  end

  describe :parse do
    before(:all) do
      json = '{"collection": {
        "href": "http://www.example.org/friends",
        "links": [
          {"rel": "feed", "href": "http://www.example.org/friends.rss"}
        ],
        "items": [
          {
            "href": "http://www.example.org/m.rowe",
            "data": [
              {"name": "full-name", "value": "Matt Rowe"}
            ]
          }
        ]
      }}'
      @collection = CollectionJSON.parse(json)
    end

    it 'should parse JSON into a Collection' do
      @collection.class.should eq(CollectionJSON::Collection)
    end

    it 'should have correct href' do
      @collection.href.should eq("http://www.example.org/friends")
    end

    it 'should handle the nested attributes' do
      @collection.items.first.href.should eq("http://www.example.org/m.rowe")
      @collection.items.first.data.count.should eq(1)
    end

    it 'should be able to be reserialized' do
      @collection.to_json.class.should eq(String)
    end

    it 'should have the correct link' do
      @collection.links.first.href.should eq("http://www.example.org/friends.rss")
    end
  end
end