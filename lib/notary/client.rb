# encoding: utf-8
# TODO remove when gem is ready
$:.unshift File.dirname(__FILE__)

# TODO throw error when context can load valid gpg data and remove this
ENV['GNUPGHOME'] ||= File.dirname(__FILE__) + '../../gnupg'

require 'reply'
require 'net/https'
require 'gpgme'
require 'json'
require 'pry'

# Notary::Client
module Notary
  class Client
    attr_reader :notaries, :dissent, :replies, :total_replies

    # Initialize with an Array of notaries URLs
    def initialize(notaries = [], dissent = 0.3)
      @notaries = notaries
      @dissent = dissent
      @replies = {}
      @total_replies = 0
      @ctx = GPGME::Ctx.new armor: true, textmode: true
    end

    # Get all replies from all notaries for a key
    def get(key)
      @notaries.each do |notary_url|
        notary_uri = URI(notary_url)
        notary_uri.query = URI.encode_www_form(key: key)

        # TODO only talk to HTTPS notaries
        res = Net::HTTP.get_response(notary_uri)
        body = JSON.parse(res.body) if res.is_a? Net::HTTPSuccess
        fpr = body["fpr"]

        # we group all replies by fingerprint, to decide how many
        # different identities are providing the same key
        @replies[fpr] ||= []
        @replies[fpr] << Notary::Reply.new(body, @ctx)
        # count total replies
        @total_replies += 1
      end

      # return a Notary::Reply
      consensus
    end

    def consensus
      # consensus is the process in which the client decides enough
      # notaries are replying with verifiable info
      #
      # there's no consensus when less than needed notaries reply
      return false unless is_there_consensus? @total_replies

      # get the most frequent fingerprint with all its replies
      fpr = most_frequent_fpr

      return false unless is_there_consensus? fpr.last.count

      # we check the signatures of the value and discard unverifiable
      # data
      #
      # we also discard fingerprint and signature mismatch just in case
      # notaries are lying
      vr = valid_replies(fpr.last, fpr.first)

      # then we check if we have enough replies and pick the latest info
      return false unless is_there_consensus? vr.count

      # return a Notary::Reply
      most_recent_reply(vr)
    end

    private

      # consensus can be reached at any point
      def is_there_consensus?(q)
        ( q / @notaries.count ) > @dissent
      end

      def most_frequent_fpr
        @replies.sort_by { |_, v| v.count }.last
      end

      def valid_replies(replies = [], fpr)
        replies.select { |r| r.valid? && r.fpr == fpr }
      end

      def most_recent_reply(replies = [])
        replies.sort_by { |r| r.time }.last
      end

  end
end
