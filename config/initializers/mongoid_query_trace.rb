# Logs a backtrace for every MongoDB command in development/test
# Works with Mongoid >= 9.0.7 using Mongo Ruby Driver command monitoring API

if Rails.env.development? || Rails.env.test? || ENV["MONGOID_QUERY_TRACER"] == "1"
  require "mongo"

  module MongoidQueryTrace
    class Subscriber
      include Mongo::Monitoring::Event

      def started(event)
      end

      def succeeded(event)
        log_event
      rescue => e
        Rails.logger.error(e.message)
      end

      def failed(event)
      end

    private

      def log_event
        # Clean up backtrace for readability in Rails
        backtrace = if defined?(Rails) && Rails.respond_to?(:backtrace_cleaner)
          Rails.backtrace_cleaner.clean(caller)
        else
          caller
        end.reject { |line| line.include?("mongoid_query_trace.rb") }.first(3)

        Rails.logger.info <<~LOG
          Query Trace:
            #{backtrace.join("\n  ")}
        LOG
      end
    end
  end

  subscriber = MongoidQueryTrace::Subscriber.new

  # Attach to global monitoring so all future clients inherit it
  Mongo::Monitoring::Global.subscribe(Mongo::Monitoring::COMMAND, subscriber)

  # Also attach to already-initialized clients that Mongoid created
  if defined?(Mongoid)
    Mongoid.clients.values.each do |client|
      next unless client.is_a?(Mongo::Client)
      client.subscribe(Mongo::Monitoring::COMMAND, subscriber)
    end
  end
end
