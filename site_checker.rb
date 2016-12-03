require 'uri'
require 'net/http'

def check_site url_text
	uri = URI.parse(url_text)
	response = Net::HTTP.get_response(uri)
	response.is_a? Net::HTTPSuccess
end

puts check_site "http://localhost:3000/"