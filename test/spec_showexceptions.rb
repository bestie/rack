require 'rack/showexceptions'
require 'rack/lint'
require 'rack/mock'

describe Rack::ShowExceptions do
  def show_exceptions(app)
    Rack::Lint.new Rack::ShowExceptions.new(app)
  end
  
  it "catches exceptions" do
    res = nil

    req = Rack::MockRequest.new(
      show_exceptions(
        lambda{|env| raise RuntimeError }
    ))

    lambda{
      res = req.get("/", "HTTP_ACCEPT" => "text/html")
    }.should.not.raise

    res.should.be.a.server_error
    res.status.should.equal 500

    res.should =~ /RuntimeError/
    res.should =~ /ShowExceptions/
    res.body.should.include '</html>'
  end

  it "handles exceptions without a backtrace" do
    res = nil

    req = Rack::MockRequest.new(
      show_exceptions(
        lambda{|env| raise RuntimeError, "", [] }
      )
    )

    lambda{
      res = req.get("/", "HTTP_ACCEPT" => "text/html")
    }.should.not.raise

    res.should.be.a.server_error
    res.status.should.equal 500

    res.should =~ /RuntimeError/
    res.should =~ /ShowExceptions/
    res.should =~ /unknown location/
  end

  def request
    Rack::MockRequest.new(
      show_exceptions(
        lambda{|env| raise RuntimeError, "It was never supposed to work" }
      )
    )
  end

  it "responds with plain text requests not preferring HTML" do
    res = nil

    lambda{
      res = request.get("/", "HTTP_ACCEPT" => "text/plain")
    }.should.not.raise

    res.should.be.a.server_error
    res.status.should.equal 500

    res.content_type.should.equal "text/plain"

    res.body.should.include "RuntimeError"
    res.body.should.include "It was never supposed to work"

    res.body.should.not.include '</html>'
  end

  it "responds with plain text to ACCEPT HEADER */*" do
    response = request.get("/", "HTTP_ACCEPT" => "text/plain")

    response.content_type.should.equal "text/plain"
  end

  it "responds with plain text when there is no accept header" do
    response = request.get("/", "HTTP_ACCEPT" => "")

    response.content_type.should.equal "text/plain"
  end

  it "responds with plain text when there is no matching mime type" do
    response = request.get("/", "HTTP_ACCEPT" => "application/json")

    response.content_type.should.equal "text/plain"
  end

  it "responds with HTML to a typical browser get document header" do
    response = request.get("/", "HTTP_ACCEPT" => "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8")

    response.content_type.should.equal "text/html"
  end
end
