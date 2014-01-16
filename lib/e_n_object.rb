class ENObject
  def self.client
    $client ||= begin
      token = "S=s1:U=8da82:E=14ad5725935:C=1437dc12d3a:P=1cd:A=en-devtoken:V=2:H=d8f71dc74b011e120ead43dcf1609542"
      t ||= EvernoteOAuth::Client.new(token: token)
      class << t
        attr_reader :token
      end
      t
    end
  end
end
