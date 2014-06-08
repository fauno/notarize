# encoding: utf-8
require 'gpgme'

module Notary
  class Reply
    attr_accessor :fpr, :sig, :value, :time, :ctx

    def initialize(res_body, ctx)
      self.fpr    =  res_body['fpr']
      self.sig    =  res_body['sig']
      self.value  =  res_body['value']
      self.time   =  res_body['time']
      self.ctx    =  ctx
    end

    # check signature and return validity
    def valid?
      # fugly api
      ctx.verify(GPGME::Data.new(sig), GPGME::Data.new(value))

      # return validity of first signature
      ctx.verify_result.signatures[0].valid?
    end
  end
end
