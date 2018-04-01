module Intrigue
module Entity
class AwsS3Bucket < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "AwsS3Bucket",
      :description => "An S3 Bucket",
      :user_creatable => false
    }
  end

  def validate_entity
    name =~ /s3.amazonaws.com/
  end

  def detail_string
    "File count: #{contents.count}" if contents
  end

end
end
end
