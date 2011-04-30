require File.dirname(__FILE__) + '/scraper'

# STREET_CODE (5), HOUSE_NUMBER (5), SUFFIX (any), UNIT (7)
# Does ruby do tail recursion?
def pad(s,l)
  return s if s == nil || s.length >= l
  pad("0" + s,l-1)
end

# There has got to be a better way to do this...
def chunk(arr, csize)
  a = Array.new
  arr.each_slice(csize) { |x| a << x }
  a
end

def line2tc(line,header)
  scode = pad(line[header["street_code"]], 5)
  hnum =  pad(line[header["house_number"]], 5)
  sfx = pad(line[header["suffix"]],0)
  unit = pad(line[header["unit"]],7)

  unit = "" if unit == "0000000"

  scode + hnum + sfx + unit
end


def read_csv(file)
  lines = File.open(file,"r",&:read).split("\n").map(&:strip).map { |x| x.split(",").map(&:strip) }
  header = lines.shift 
  header = header.zip(0.upto(header.size)).inject(Hash.new) { |h,(k,v)| h[k.downcase] = v; h }

  [header, lines]
end

def process_chunk(list, header, file)
  csv = scrape_chunk(list, header) .map { |x| x.join(",") }.join("\n")
  File.open(file,"w+") { |f| f.write(csv + "\n") }
end

def scrape_chunk(list, header)
  output_headers = nil
  data = list.map do |l|
    tcode = line2tc(l,header)
    
    begin
      scrape_data = Philly::scrape(tcode)
    rescue Exception => e
      puts "Failed to scrape"
      puts list
    end

    header_keys = header.values.sort
    output_headers = header_keys.map { |k| header.invert[k] } + scrape_data.keys + ["tcode"] unless output_headers
    l + scrape_data.values + [tcode]
  end

  [output_headers] + data
end

def process_as_chunks(list,header,file,chunksize=1000,startat=0,goto=-1)
  chunks = chunk(list,chunksize)[startat..goto]
  puts "About to process #{chunks.size} chunks (starting at #{startat}, going to #{goto}) (chunk size of #{chunksize})"
  end_offset = if (goto == -1) 
                 0 
               else 
                 goto
               end

  padsize = chunks.size.size

  chunks.each_with_index do |lst,idx|
    puts "Processing chunk #{idx + startat} of #{chunks.size-1 + startat + end_offset}"
    process_chunk(lst, header, "#{file}_#{pad((idx + startat).to_s,padsize)}_of_#{chunks.size-1 + startat + end_offset}.csv")
  end

end

def get_or_else(hash,key,els)
  if (hash.has_key? key)
    hash[key]
  else
    els
  end
end

header, lines = read_csv("BRT_Address_List.csv")

l = lines.first
tcode = line2tc(l, header)

require 'pp'
#process(lines[0..10], header).map {|x| x.join(",") }.join("\n")
#process_chunk(lines[0..1], header, "testout.csv")
arghash = Hash.new
ARGV.each_slice(2) { |s1,s2| arghash[s1] = s2 }

from = get_or_else(arghash, "-from", 0).to_i
to = get_or_else(arghash, "-to", -1).to_i
outp = get_or_else(arghash, "-output", nil)
chunksize = get_or_else(arghash, "-chunk", 100)

puts "Options: -from, -to, -output [required], -chunk"
raise "You must specify -ouput file prefix" unless outp

lines = lines[0..20]

process_as_chunks(lines, header, outp, chunksize.to_i, from, to)

#pp lines.size
#pp Philly::scrape(tcode)




