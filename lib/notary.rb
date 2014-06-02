# encoding: utf-8
# dependencies
require 'sinatra'
require 'tokyocabinet'
require 'gpgme'
require 'json'

# use a local key, see bin/genkey
ENV['GNUPGHOME'] = File.dirname(__FILE__) + '/../gnupg'

# load context and crypto for the key
GPG = GPGME::Crypto.new armor: true
CTX = GPGME::Ctx.new armor: true, textmode: true

# create or open a tokyo cabinet table
TOKYO = TokyoCabinet::TDB::new
TOKYO.open('db/notary.tct', TokyoCabinet::TDB::OWRITER | TokyoCabinet::TDB::OCREAT)

# print public ring
CTX.each_key do |k|
  puts k
end

# pull results
# key: the key for the info to pull
get '/' do
  value = TOKYO.get(params[:key])

# if there's something, return it as json
  if !value.nil?
    halt 200, value.to_json
  else
    halt 404, { msg: 'not_found' }.to_json
  end
end

# push info here
# key:   the key for the info we want to store
# value: the value
# sig:   the gpg sig of the value
post '/' do
# the notary verifies the signature
  CTX.verify(GPGME::Data.new(params[:sig]), GPGME::Data.new(params[:value]))

# get the signature
  sig = CTX.verify_result.signatures[0]

# if the sig is valid
  if sig.valid?
# when there's a previous value, check both signers fingerprints.  if
# they don't match, stop everything since someone's trying to modify
# info they didn't post originally.
    prev_value = TOKYO.get(params[:key])
    if !prev_value.nil? && sig.fpr != prev_value['fpr']
      halt 403, { msg: 'not_cool' }.to_json
    end

# values to store, we use string keys to avoid an implicit conversion
# error on put()
    store = {
      'value' => params[:value],
      'sig' => params[:sig],
      'fpr' => sig.fpr
    }

# store the data and return OK to the client
    if TOKYO.put(params[:key], store) && TOKYO.sync
      halt 200, { msg: 'ok' }.to_json
    end
# otherwise complain
  else
    puts 'invalid or unrecognized: ' + sig.fpr
    halt 400, { msg: 'invalid' }.to_json
  end
end

# send a key here
# pubkey: ascii armored key(s)
post '/import' do
  if GPGME::Key.import(params[:pubkey]).imported > 0
    halt 200, { msg: 'ok' }.to_json
  else
    halt 400, { msg: 'invalid' }.to_json
  end
end
