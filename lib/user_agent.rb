require 'user_agent/comparable'
require 'user_agent/browsers'
require 'user_agent/operating_systems'
require 'user_agent/version'

class UserAgent
  # http://www.texsoft.it/index.php?m=sw.php.useragent
  MATCHER = %r{
    ^([^/\s]+)        # Product
    /?([^\s]*)        # Version
    (\s\(([^\)]*)\))? # Comment
  }x.freeze

  # http://my.opera.com/community/openweb/idopera/
  OPERA_MATCHER = %r{
    ^([^/\s]+)            # Product
    /?([^\s]*)            # Old Version
    (\s\(([^\)]*)\))?     # Comment
    .*(Version/([^/\s]+)) # Version
  }x.freeze

  DEFAULT_USER_AGENT = "Mozilla/4.0 (compatible)"

  def self.parse(string)
    if string.nil? || string == ""
      string = DEFAULT_USER_AGENT
    end

    agents = []

    # Opera has a different user agent since version 10
    # Check for that version and then continue matching
    product = string.to_s.match(MATCHER)[1]
    if product && product == "Opera" && string =~ /Version\/\d+/
      match = string.to_s.match(OPERA_MATCHER)
      agents << new(match[1], match[6], match[4])
      # Trim the string based on the original matcher and continue
      standard_match = string.to_s.match(MATCHER)
      string = string[standard_match[0].length..-1].strip
    end

    while m = string.to_s.match(MATCHER)
      agents << new(m[1], m[2], m[4])
      string = string[m[0].length..-1].strip
    end
    Browsers.extend(agents)
    agents
  end

  attr_reader :product, :version, :comment

  def initialize(product, version = nil, comment = nil)
    if product
      @product = product
    else
      raise ArgumentError, "expected a value for product"
    end

    if version && !version.empty?
      @version = Version.new(version)
    else
      @version = nil
    end

    if comment.respond_to?(:split)
      @comment = comment.split("; ")
    else
      @comment = comment
    end
  end

  include Comparable

  # Any comparsion between two user agents with different products will
  # always return false.
  def <=>(other)
    if @product == other.product
      if @version && other.version
        @version <=> other.version
      else
        0
      end
    else
      false
    end
  end

  def eql?(other)
    @product == other.product &&
      @version == other.version &&
      @comment == other.comment
  end

  def to_s
    to_str
  end

  def to_str
    if @product && @version && @comment
      "#{@product}/#{@version} (#{@comment.join("; ")})"
    elsif @product && @version
      "#{@product}/#{@version}"
    elsif @product && @comment
      "#{@product} (#{@comment.join("; ")})"
    else
      @product
    end
  end
end
