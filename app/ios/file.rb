# iOS has problems sending binary strings via Net requests
# In this case we'll use its predefined NSData format type
# This solution may be temporare
# On Android, a regular string should be returned

class File
  def self.get_data(file)
    return NSData.dataWithContentsOfFile(file)
  end
end
