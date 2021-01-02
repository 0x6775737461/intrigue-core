module Intrigue
  module Task
  module Enrich
  class EmailAddress < Intrigue::Task::BaseTask
  
    def self.metadata
      {
        :name => "enrich/email_address",
        :pretty_name => "Enrich EmailAddress",
        :authors => ["jcran"],
        :description => "Fills in details for an EmailAddress",
        :references => [],
        :allowed_types => ["EmailAddress"],
        :type => "enrichment",
        :passive => true,
        :example_entities => [
          {"type" => "EmailAddress", "details" => {"name" => "test@intrigue.io"}}],
        :allowed_options => [],
        :created_types => ["Domain"]
      }
    end
  
    def run
  
      # always create domain as an unscoped
      email_address = _get_entity_name.strip
      domain = email_address.split("@").last
      create_unscoped_dns_entity_from_string domain
      
    end
  
  end
  end
  end
  end