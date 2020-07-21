module Intrigue
module Task
module Data

  def dev_server_name_patterns
    [
      /-stage$/, /-staging$/,/-dev$/,/-development$/,/-test$/,/-qa$/, 
      /^staging-/,/^dev-/,/^development-/,/^test-/,/^qa-/,
      /^staging\./,/^dev\./,/^development\./,/^test\./,/^qa\./,
      /^test/,/^staging/,/^qa/
    ] # possibly too aggressive
  end

  def _service_name_for(port_num, proto)
    service_name = nil
    file = File.open("#{$intrigue_basedir}/data/service-names-port-numbers.csv","r")
    file.read.split("\n").each do |line|
      data = line.split(",")
      line_port_num = data[1]
      if line_port_num.to_i == port_num.to_i
        if "#{data[2]}".upcase == proto.upcase
          service_name = "#{data[0]}".upcase if data[0]
        end
      end
    end
    service_name || "UNKNOWN"
  end

  def _allocated_ipv4_ranges(filter="ALLOCATED")
    ranges = []
    file = File.open("#{$intrigue_basedir}/data/iana/ipv4-address-space.csv","r")
    file.read.split("\n").each do |line|
      next unless line =~ /#{filter}/
      range = line.split(",").first
      ranges << range.gsub(/^0*/, "").gsub("/8",".0.0.0/8")
    end
  ranges
  end

  def simple_web_creds
   [
      {:username => "admin",          :password => "admin"},
      {:username => "administrator",  :password => "administrator"},
      {:username => "anonymous",      :password => "anonymous"},
      {:username => "cisco",          :password => "cisco"},
      {:username => "demo",           :password => "demo"},
      {:username => "demo1",          :password => "demo1"},
      {:username => "guest",          :password => "guest"},
      {:username => "test",           :password => "test"},
      {:username => "test1",          :password => "test1"},
      {:username => "test123",        :password => "test123"},
      {:username => "test123!!",      :password => "test123!!"}
    ]
  end

  def cymru_ip_whois_lookup(ip)
    whois_detail = Intrigue::Client::Search::Cymru::IPAddress.new.whois(ip)
    { 
      :net_asn => "AS#{whois_detail[0]}",
      :net_block => "#{whois_detail[1]}",
      :net_country_code => "#{whois_detail[2]}",
      :net_rir => "#{whois_detail[3]}",
      :net_allocation_date => "#{whois_detail[4]}",
      :net_name => "#{whois_detail[5]}"
    }
  end

  def get_internal_domains
    ["ec2.internal"]
  end

  def get_cdn_domains
    [
      "hexagon-cdn.com",
      "edgecastcdn.net",
      "akamaitechnologies.com",
      "static.akamaitechnologies.com",
      "1e100.net"
    ]   
  end


  def get_universal_cert_domains
    [
      "acquia-sites.com",
      "careers.talemetry.com",
      "chinanetcenter.com",
      "chinacloudsites.cn",
      "cloudflare.com",
      "cloudflaressl.com",
      "distilnetworks.com",
      "edgecastcdn.net",
      "helloworld.com",
      "hexagon-cdn.com", # TODO - worth revisiting, may include related hosts
      "fastly.net",
      "freshdesk.com",
      "jiveon.com",
      "incapsula.com",
      "lithium.com",
      "sucuri.net",
      "swagcache.com",
      "wpengine.com",
      "yottaa.net"
    ]
  end

  def scannable_udp_ports
    
    udp_ports = ""
    udp_ports << "53,"      # dns
    udp_ports << "123,"     # ntp
    udp_ports << "135,"     # msrpc
    udp_ports << "139,"     # netbios session
    udp_ports << "161,"     # snmp
    udp_ports << "500,"     # isakmp
    udp_ports << "631,"     # ipp
    udp_ports << "1434,"    # msrpc
    udp_ports << "1900,"    # upnp
    udp_ports << "2049,"    # nfs 
    udp_ports << "17185"    # vxworks https://blog.rapid7.com/2010/08/02/new-vxworks-vulnerabilities/

  udp_ports.split(",")
  end

  def fingerprintable_udp_ports
    [161]
  end

  def fingerprintable_tcp_ports
    ports = [21,22,23,25].concat(scannable_web_ports)
  ports
  end

  def scannable_web_ports
    [ 
      80,81,82,83,84,85,88,443,888,3000,6443,7443,
      8000,8080,8081,8087,8088,8089,8090,8095,
      8098,8161,8180,8443,8880,8888,9443,10000 
    ]
  end

  def scannable_tcp_ports

    # https://duo.com/decipher/mapping-the-internet-whos-who-part-three
    # https://docs.oracle.com/cd/E16340_01/core.1111/e10105/portnums.htm
    # https://svn.nmap.org/nmap/nmap-services
    # https://docs.google.com/spreadsheets/d/1r_IriqmkTNPSTiUwii_hQ8Gwl2tfTUz8AGIOIL-wMIE/pub?output=html

    tcp_ports = ""
    tcp_ports << "21,"
    tcp_ports << "22,"
    tcp_ports << "23,"
    tcp_ports << "35,"
    tcp_ports << "80,81,"
    tcp_ports << "443,"
    tcp_ports << "445,"
    tcp_ports << "502,503,"
    tcp_ports << "993,"             # imaps
    tcp_ports << "995,"             # pops
    tcp_ports << "1723,"            # pptp
    tcp_ports << "1883,"
    tcp_ports << "2181,"
    tcp_ports << "2222,"
    tcp_ports << "2888,"
    tcp_ports << "3306,"            # mysql
    tcp_ports << "3389,"            # RDP
    tcp_ports << "3888,"
    tcp_ports << "4443,"            # HTTPS
    tcp_ports << "4444,"            # Bind
    tcp_ports << "4505,4506,"       # salt stack
    tcp_ports << "4786,"
    tcp_ports << "5000,"            # Oracle WebLogic Server Node Manager Port	
    tcp_ports << "5556,"
    tcp_ports << "5900,5901,"       # vnc
    tcp_ports << "6379,"            # redis 
    tcp_ports << "6443,"
    tcp_ports << "7001,7002,"       # Oracle WebLogic Server Listen Port for Administration Server 
                                    # Oracle WebLogic Server SSL Listen Port for Administration Server	
    tcp_ports << "7443,"        
    tcp_ports << "7777,"
    tcp_ports << "8001,"            # Oracle WebLogic Server Listen Port for Managed Server	
    tcp_ports << "8009,"
    tcp_ports << "8032,"
    tcp_ports << "8080,8081,"       # HTTP
    tcp_ports << "8278,"
    tcp_ports << "8291,"
    tcp_ports << "8443,"
    tcp_ports << "8883,"
    tcp_ports << "9000,9001,"
    tcp_ports << "9091,9092,"
    tcp_ports << "9094,"
    tcp_ports << "9200,9201,"         # elasticsearch
    tcp_ports << "9300,9301,"         # elasticsearch
    tcp_ports << "9443,"
    tcp_ports << "10443,"
    tcp_ports << "11443,"
    tcp_ports << "11994,"
    tcp_ports << "12443,"
    tcp_ports << "13443,"
    tcp_ports << "20443,"
    tcp_ports << "27017,27018,27019," # mongodb
    tcp_ports << "22222,"
    tcp_ports << "30443,"
    tcp_ports << "40443,"
    tcp_ports << "53413"

  tcp_ports.split(",")
  end
  
  def geolocate_ip(ip)

    return nil unless File.exist? "#{$intrigue_basedir}/data/geolitecity/GeoLite2-City.mmdb"

    begin 
      db = MaxMindDB.new("#{$intrigue_basedir}/data/geolitecity/GeoLite2-City.mmdb", MaxMindDB::LOW_MEMORY_FILE_READER)

      _log "looking up location for #{ip}"

      #
      # This call attempts to do a lookup
      #
      location = db.lookup(ip)

      #translate the hash to remove some of the multiingual stuff
      hash = {}

      hash[:city] = location.to_hash["city"]["names"]["en"] if location.to_hash["city"]
      hash[:continent] = location.to_hash["continent"]["names"]["en"] if location.to_hash["continent"]
      hash[:continent_code] = location.to_hash["continent"]["code"] if location.to_hash["continent"]
      hash[:country] = location.to_hash["country"]["names"]["en"] if location.to_hash["country"]
      hash[:country_code] = location.to_hash["country"]["iso_code"] if location.to_hash["country"]
      hash.merge(location.to_hash["location"].map { |k, v| [k.to_sym, v] }.to_h) if location.to_hash["location"]
      hash[:postal] = location.to_hash["postal"]["code"] if location.to_hash["postal"]
      hash[:registered_country] = location.to_hash["registered_country"]["names"]["en"] if location.to_hash["registered_country"]
      hash[:registered_country_code] = location.to_hash["registered_country"]["iso_code"] if location.to_hash["registered_country"]
      hash[:subdivisions] = location.to_hash["subdivisions"].map{|s| s["names"]["en"] } if location.to_hash["subdivisions"]
      
    rescue RuntimeError => e
      _log "Error reading file: #{e}"
    rescue ArgumentError => e
      _log "Argument Error #{e}"
    rescue Encoding::InvalidByteSequenceError => e
      _log "Encoding error: #{e}"
    rescue Encoding::UndefinedConversionError => e
      _log "Encoding error: #{e}"
    end

  hash
  end


end
end
end
