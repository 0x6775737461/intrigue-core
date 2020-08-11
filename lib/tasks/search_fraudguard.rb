module Intrigue
module Task
class SearchFraudGuard < BaseTask


  def self.metadata
    {
      :name => "search_fraudguard",
      :pretty_name => "Search FraudGuard",
      :authors => ["Anas Ben Salah"],
      :description => "This task hits FraudGuard api ",
      :references => ["https://docs.fraudguard.io/"],
      :type => "threat_check",
      :passive => true,
      :allowed_types => ["IpAddress"],
      :example_entities => [{"type" => "IpAddress", "details" => {"name" => "1.1.1.1"}}],
      :allowed_options => [],
      :created_types => []
    }
  end


  ## Default method, subclasses must override this
  def run
    super

      #get entity name and type
      entity_name = _get_entity_name

      #get keys for API authorization
      username =_get_task_config("fraudguard_username")
      password =_get_task_config("fraudguard_api_key")

      unless password or username
        _log_error "unable to proceed, no API key for AdblockPlus provided"
        return
      end

      # Get responce

      response = JSON.parse(get_ip("api.fraudguard.io","/ip/#{entity_name}",username,password))

      if response
        _create_linked_issue("suspicious_activity_detected", {
          status: "confirmed",
          description: "This ip was flagged by fraudguard.io for #{response["threat"]} threat with risk level: #{response["risk_level"]} ",
          fraudguard_details: response
        })
        # Also store it on the entity
        blocked_list = @entity.get_detail("suspicious_activity_detected") || []
        @entity.set_detail("suspicious_activity_detected", blocked_list.concat([{}]))
    end
  end #end run

  #retrieves IP reputation data for a specific IP
  def get_ip(server,path,username,password)

    http = Net::HTTP.new(server,443)
    req = Net::HTTP::Get.new(path)
    http.use_ssl = true
    req.basic_auth username, password
    response = http.request(req)
    return response.body

  end

end
end
end
