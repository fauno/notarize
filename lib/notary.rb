require 'sinatra'
require 'tokyocabinet'

TOKYO = TokyoCabinet::HDB::new
TOKYO.open('notary.tch', TokyoCabinet::HDB::OWRITER | TokyoCabinet::HDB::OCREAT)

get '/' do
  TOKYO.get(params[:key])
end

post '/' do
  TOKYO.put(params[:key], params[:value])
  TOKYO.sync
end
