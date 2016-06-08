# frozen_string_literal: true
module Callback
  class MeasurementListUpdaterCallback
    def on_success(_status, options)
      options.symbolize_keys!
      # On success, queue up updating measurement totals
      options[:json].each do |measurement|
        GrSync::WithGrWorker.queue_call(options[:gr_client_params],
                                        GrSync::MeasurementPush, :update_totals, measurement)
      end
    end
  end
end
