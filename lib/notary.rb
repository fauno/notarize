require 'sinatra'
require 'tokyocabinet'
require 'gpgme'
require 'json'

ENV['GNUPGHOME'] = File.dirname(__FILE__) + '/../gnupg'

TOKYO = TokyoCabinet::TDB::new
TOKYO.open('db/notary.tct', TokyoCabinet::TDB::OWRITER | TokyoCabinet::TDB::OCREAT)

GPG = GPGME::Crypto.new armor: true
CTX = GPGME::Ctx.new armor: true, textmode: true

CTX.each_key do |k|
  puts k
end

get '/' do
  value = TOKYO.get(params[:key])

  if !value.nil?
    value.to_json
  else
    { error: "not_found" }.to_json
  end
end

post '/' do
  CTX.verify(GPGME::Data.new(params[:sig]), GPGME::Data.new(params[:value]))

  sig = CTX.verify_result.signatures[0]

  if sig.valid?

# values to store, we use string keys to avoid an implicit conversion
# error on put()
    store = {
      'value' => params[:value],
      'sig' => params[:sig],
      'fpr' => sig.fpr
    }

    if TOKYO.put(params[:key], store)
      TOKYO.sync
      'OK'
    end
  else
    puts 'invalid or unrecognized: ' + sig.fpr
    'INVALID'
  end
end

post '/import' do
  'OK' if GPGME::Key.import(params[:pubkey]).imported > 0
end
