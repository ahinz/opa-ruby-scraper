require 'rest_client'
require 'nokogiri'
require 'json'

module Philly
  BASE_ADDR = "http://opa.phila.gov/opa.apps/Search/SearchResults.aspx?id="

  FIELDS = ["PropertyAddress",
            "PropertyUnitNumber",
            "PropertyZipCode",
            "OwnerAccountNumber", 
            "OwnerName", 
            "OwnerMailAdd_Street", 
            "OwnerMailAdd_City",
            "OwnerMailAdd_State",
            "OwnerMailAdd_Zip"]
  
  def self.scrape(tcode)
    raise "The 10-code should be not be nil" if tcode == nil
    doc = Nokogiri::HTML(RestClient.get(BASE_ADDR + tcode))
    
    FIELDS.inject(Hash.new) do |hash,field|
      hash[field] = scrape_id("lbl_" + field,doc,tcode).strip
      hash
    end
  end

  def self.scrape_id(id,doc,fid)
    possible = doc.css("##{id}")
    if (possible == nil || possible.size == 0)
      raise "Error - could not find valid #{id} for fid #{fid}"
    end

    possible.first.children.to_s.gsub("<br>","|")
  end
end

#pp Philly::scrape("7884004648")

