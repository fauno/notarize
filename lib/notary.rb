require 'sinatra'
require 'tokyocabinet'
require 'gpgme'

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

  GPG.clearsign(value).to_s if !value.nil?
end

post '/' do
  TOKYO.put(params[:key], params[:value])
  TOKYO.sync
end

post '/import' do
  'OK' if GPGME::Key.import(params[:pubkey]).imported > 0
end
