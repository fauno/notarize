# encoding: utf-8
require 'net/https'
require 'gpgme'
require 'json'
require 'pry'

# Notary::Client
module Notary
  class Client
    attr_reader :notaries, :dissent, :replies

    # Initialize with an Array of notaries URLs
    def initialize(notaries = [], dissent = 0.3)
      @notaries = notaries
      @dissent = dissent
      @replies = []
      @ctx = GPGME::Ctx.new armor: true, textmode: true
    end

    # Get all replies from all notaries for a key
    def get(key)
      @notaries.each do |notary_url|
        notary_uri = URI(notary_url)
        notary_uri.query = URI.encode_www_form(key: key)

        # TODO only talk to HTTPS notaries
        res = Net::HTTP.get_response(notary_uri)

        @replies << JSON.parse(res.body) if res.is_a? Net::HTTPSuccess

      end

      return consensus

    end

    def consensus
      # consensus is the process in which the client decides enough
      # notaries are replying with verifiable info
      #
      # there's no consensus when less than needed notaries reply
      return false if !is_there_consensus? @replies.count

      # we group all replies by fingerprint, to decide how many
      # different identities are providing the same key
      @replies = @replies.group_by { |v| v["fpr"] }

      # get the most frequent fingerprint
      fpr = Hash[*@replies.map { |k,v| [ v.count, k ] }.flatten].sort.last[1]

      return false if !is_there_consensus? @replies[fpr].count

      # we check the signatures of the value and discard unverifiable
      # data
      #
      # we also discard fingerprint and signature mismatch just in case
      # notaries are lying
      @replies[fpr].map! { |reply| reply if fpr == verify_reply(reply) }

      # then we check if we have enough replies and pick the latest info
      return false if !is_there_consensus? @replies[fpr].count
    end

    private

      # consensus can be reached at any point
      def is_there_consensus?(q)
        ( q / @notaries.count ) > @dissent
      end

      # return the fingerprint if the signature is valid
      def verify_reply(reply)
        @ctx.verify(GPGME::Data.new(reply[:sig]), GPGME::Data.new(reply[:value]))

        if (sig = @ctx.verify_result.signatures[0]).valid?
          sig.fpr
        end
      end

  end
end
