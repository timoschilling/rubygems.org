require 'test_helper'

class RedirectorTest < ActiveSupport::TestCase
  def app
    Rack::Builder.new do
      use Redirector
      run lambda {|env| [200, {"Content-Type" => "text/html"}, []]}
    end
  end

  should "forward requests that don't match" do
    get "/specs.4.8.gz", {}, {"HTTP_HOST" => HOST}
    assert last_response.ok?
  end

  should "redirect requests from a non-HOST domain" do
    path = "/gems/rails"
    get path, {}, {"HTTP_HOST" => "gems.rubyforge.org"}

    assert_equal 301, last_response.status
    assert_equal "http://#{HOST}#{path}", last_response.headers["Location"]
  end

  should "redirect requests from a non-HOST domain with query string" do
    path = "/search"
    get path, {"query" => "rush"}, {"HTTP_HOST" => "gems.rubyforge.org"}

    assert_equal 301, last_response.status
    assert_equal "http://#{HOST}#{path}?query=rush", last_response.headers["Location"]
  end

  should "not redirect requests to the API from a non-HOST domain" do
    path = "/api/v1/gems"
    post path, {}, {"HTTP_HOST" => "gems.rubyforge.org"}

    assert last_response.ok?
  end

  %w[/book
     /book/42
     /chapter/58
     /read/book/2
     /export
     /shelf/9000
     /syndicate.xml].each do |uri|
    should "redirect to docs.rubygems.org when #{uri} is hit" do
      get uri, {}, {"HTTP_HOST" => HOST}

      assert_equal 301, last_response.status
      assert_equal "http://docs.rubygems.org#{uri}", last_response.headers["Location"]
    end
  end
end
