module Intrigue
module Task
module Enrich
class NetworkService < Intrigue::Task::BaseTask

  def self.metadata
    {
      :name => "enrich/network_service",
      :pretty_name => "Enrich Network Service",
      :authors => ["jcran"],
      :description => "Fills in details for a Network Service",
      :references => [],
      :type => "enrichment",
      :passive => false,
      :allowed_types => ["NetworkService"],
      :example_entities => [
        { "type" => "NetworkService", "details" => { "name" => "1.1.1.1:1111/tcp" } }
      ],
      :allowed_options => [],
      :created_types => []
    }
  end

  ## Default method, subclasses must override this
  def run
    _log "Enriching... Network Service: #{_get_entity_name}"

    ###
    ### First, normalize the nane - split out the various attributes
    ###
    entity_name = _get_entity_name
    ip_address = entity_name.split(":").first
    port = entity_name.split(":").last.split("/").first.to_i
    proto = entity_name.split(":").last.split("/").first.upcase

    _set_entity_detail("ip_address", ip_address) unless _get_entity_detail("ip_address")
    _set_entity_detail("port", port) unless _get_entity_detail("port")
    _set_entity_detail("proto", proto) unless _get_entity_detail("proto")

    ###
    ###
    ###
    fingerprint_service(ip_address, port, proto) 
    
    ###
    ### Handle SNMP as a special treat
    ###
    enrich_snmp if port == 161 && proto.upcase == "UDP"

    # Unless we could verify futher, consider these noise
    noise_networks = [
      "CLOUDFLARENET - CLOUDFLARE, INC., US", 
      "GOOGLE, US", 
      "CLOUDFLARENET, US", 
      "GOOGLE-PRIVATE-CLOUD, US", 
      "INCAPSULA, US", 
      "INCAPSULA - INCAPSULA INC, US"
    ]

    # drop them if we don't have a fingerprint
    if noise_networks.include?(_get_entity_detail("net_name")) && (_get_entity_detail("fingerprint") || []).empty?
      @entity.deny_list = true && @entity.hidden = true && @entity.scoped = false
      @entity.save
    end
  
  end

  def fingerprint_service(ip_address,port=nil, proto="TCP")

    # Use intrigue-ident code to request the banner and fingerprint
    _log "Grabbing banner and fingerprinting!"

    ident_matches = generate_ftp_request_and_check(ip_address) || {} if port == 21
    ident_matches = generate_smtp_request_and_check(ip_address) || {} if port == 25
    #ident_matches = generate_http_requests_and_check(_get_entity_name) || {} if port == 80 || port == 443
    ident_matches = generate_snmp_request_and_check(ip_address) || {} if port == 161 && proto.upcase == "UDP"
    ident_matches = generate_ssh_request_and_check(ip_address) || {} if port == 22
    ident_matches = generate_telnet_request_and_check(ip_address) || {} if port == 23

    unless ident_matches
      _log "Unable to fingerprint!"
      return
    end

    ident_fingerprints = ident_matches["fingerprints"] || []
    _log "Got #{ident_fingerprints.count} fingerprints!"

    # get the request/response we made so we can keep track of redirects
    ident_banner = ident_matches["banner"]

    if ident_fingerprints.count > 0
      ident_fingeprints = add_vulns_by_cpe(ident_fingerprints)
    end

    _set_entity_detail "banner", ident_banner
    _set_entity_detail "fingerprint", ident_fingerprints
  end

  def enrich_snmp
    _log "Enriching... SNMP service: #{_get_entity_name}"

    port = _get_entity_detail("port").to_i || 161
    ip_address = _get_entity_detail "ip_address"

    # Create a tempfile to store results
    temp_file = "#{Dir::tmpdir}/nmap_snmp_info_#{rand(100000000)}.xml"

    nmap_string = "nmap #{ip_address} -sU -p #{port} --script=snmp-info -oX #{temp_file}"
    nmap_string = "sudo #{nmap_string}" unless Process.uid == 0

    _log "Running... #{nmap_string}"
    nmap_output = _unsafe_system nmap_string

    # parse the file and get output, setting it in details
    doc = File.open(temp_file) { |f| Nokogiri::XML(f) }

    service_doc = doc.xpath("//service")
    begin
      if service_doc && service_doc.attr("product")
        snmp_product = service_doc.attr("product").text
      end
    rescue NoMethodError => e
      _log_error "Unable to find attribute: product"
    end

    begin
      script_doc = doc.xpath("//script")
      if script_doc && script_doc.attr("output")
        script_output = script_doc.attr("output").text
      end
    rescue NoMethodError => e
      _log_error "Unable to find attribute: output"
    end


    _log "Got SNMP details:#{script_output}"

    _set_entity_detail("product", snmp_product)
    _set_entity_detail("script_output", script_output)

    # cleanup
    begin
      File.delete(temp_file)
    rescue Errno::EPERM
      _log_error "Unable to delete file"
    end
  end

end
end
end
end