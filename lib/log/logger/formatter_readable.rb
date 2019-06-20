module Log
  class Logger < Ougai::Logger
    class FormatterReadable < Ougai::Formatters::Readable
      def initialize(*args)
        super
      end

      def _call(severity, time, progname, data)
        data.delete(:request)
        super(severity, time, progname, data)
      end
    end
  end
end
