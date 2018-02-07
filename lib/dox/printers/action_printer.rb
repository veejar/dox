module Dox
  module Printers
    class ActionPrinter < BasePrinter
      def print(action)
        self.action = action
        @output.puts action_title
        @output.puts action_uri_params if action.uri_params.present?

        action.examples.each do |example|
          example.action = action
          example_printer.print(example)
        end
      end

      private

      attr_accessor :action

      def action_title
        <<-HEREDOC

### #{action.name} [#{action.verb.upcase} #{action.path}]
#{print_desc(action.desc)}
        HEREDOC
      end

      def action_uri_params
        <<-HEREDOC
+ Parameters
#{formatted_params(action.uri_params)}
        HEREDOC
      end

      def example_printer
        @example_printer ||= ExamplePrinter.new(@output)
      end

      def formatted_params(uri_params)
        uri_params.map do |param, details|
          value = details[:value].present? ? ":`#{CGI.escape(details[:value].to_s)}`" : ''
          type_and_required = [details[:type], details[:required]].compact
          desc = "    + #{CGI.escape(param.to_s)}#{value} (#{type_and_required.join(', ')})"
          desc += " - #{details[:description]}" if details[:description].present?
          desc += "\n        + Default: #{details[:default]}" if details[:default].present?
          desc
        end.flatten.join("\n")
      end
    end
  end
end
