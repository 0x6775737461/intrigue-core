module Intrigue
module Entity
class DnsRecord < Intrigue::Core::Model::Entity
  
  include Intrigue::Task::Dns

  def self.metadata
    {
      :name => "DnsRecord",
      :description => "A Dns Record",
      :user_creatable => true,
      :example => "test.intrigue.io"
    }
  end

  def validate_entity
    name =~ dns_regex
  end

  def detail_string
    return "" unless details["resolutions"]
    details["resolutions"].each.group_by{|k| k["response_type"] }.map{|k,v| "#{k}: #{v.length}"}.join("| ")
  end

  def enrichment_tasks
    ["enrich/dns_record"]
  end

  ###
  ### SCOPING
  ###
  def scoped?(conditions={}) 
    return true if self.allow_list
    return false if self.deny_list

  # if we didnt match the above and we were asked, default to true
  false
  end

end
end
end
