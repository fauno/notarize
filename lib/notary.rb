require 'sinatra'
require 'tokyocabinet'
require 'gpgme'
require 'json'

ENV['GNUPGHOME'] = File.dirname(__FILE__) + '/../gnupg'

TOKYO = TokyoCabinet::HDB::new
TOKYO.open('notary.tch', TokyoCabinet::HDB::OWRITER | TokyoCabinet::HDB::OCREAT)

GPG = GPGME::Crypto.new armor: true
CTX = GPGME::Ctx.new armor: true, textmode: true

CTX.each_key do |k|
  puts k
end

get '/' do
  value = TOKYO.get(params[:key])

  if !value.nil?
    {
      sig: GPG.sign(value).to_s,
      value: value,
      key: params[:key]
    }.to_json
  else
    { error: "not_found" }.to_json
  end
end

post '/' do
  GPG.verify(params[:value]) do |sig|
    if sig.valid?
      if TOKYO.put(params[:key], params[:value])
        TOKYO.sync
        'OK'
      end
    else
      'INVALID'
    end
  end
end

post '/import' do
  'OK' if GPGME::Key.import(params[:pubkey]).imported > 0
end
