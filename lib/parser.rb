module GreenButton
	require 'nokogiri'
	require 'open-uri'

	class Parser
		attr_accessor :doc

		def initialize(doc)
			@doc = doc
		end

		def parse_greenbutton_xml
			parsed_data = Data.new
			parsed_data.usage_points = parsed_usage_points
			parsed_data
		end

		def parsed_usage_points
			usage_points = []
			doc.xpath('//UsagePoint').each do |usage_point|
				usage_points << parsed_usage_point(usage_point)
			end
			usage_points
		end

		def parsed_usage_point(usage_point_xml)
			point = UsagePoint.new
			rules = { service_kind: 'ServiceCategory/kind', self_href: "../../link[@rel='self']/@href" }
			generic_parser(usage_point_xml, rules, point)

			parse_related(usage_point_xml, point)			
			point
		end

		def parse_related(xml, point)
			related_hrefs = []
			xml.xpath("../../link[@rel='related']/@href").each do |rel|
				related_hrefs << rel.text
				related_entry = xml.xpath("//link[@rel='self' and @href='#{rel.text}']/..")
				parse_entry(related_entry, point)
			end
			point.related_hrefs = related_hrefs
		end

		def parse_entry(xml, point)
			parse_local_time_parameters(xml.xpath('content/LocalTimeParameters'), point)
		end

		def parse_local_time_parameters(xml, point)
			time = LocalTimeParameters.new
			rules = { dst_end_rule: "dstEndRule", dst_offset: "dstOffset", dst_start_rule: "dstStartRule", tz_offset: "tzOffset" }
			generic_parser(xml, rules, time)
			point.local_time_parameters = time
		end

		def generic_parser(xml, rules, append_to)
			rules.each do |attr_name,xpath|
				text = xml.xpath(xpath).text
				append_to.send(attr_name.to_s+"=", text)
			end
		end
	end

	class Data
		attr_accessor :usage_points
	end

	class UsagePoint
		attr_accessor :service_kind, :self_href, :related_hrefs, :local_time_parameters
	end

	class LocalTimeParameters
		attr_accessor :dst_end_rule, :dst_offset, :dst_start_rule, :tz_offset
	end

	class Loader
		attr_accessor :xml_file

		# could also load this from the data custodian:feed
		# url = "http://services.greenbuttondata.org:80/DataCustodian/espi/1_1/resource/RetailCustomer/1/DownloadMyData"

		def load_xml_from_web(url)
			@xml_file = Nokogiri.XML(open(url))
			@xml_file.remove_namespaces!
		end

		def load_xml_from_file(path)
			@xml_file = Nokogiri.XML(File.open(path, 'rb'))
			@xml_file.remove_namespaces!
		end
	end
end

