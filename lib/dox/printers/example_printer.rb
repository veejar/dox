module Dox
  module Printers
    class ExamplePrinter < BasePrinter
      def print(example)
        self.example = example
        print_example_request
        print_example_response
      end

      private

      attr_accessor :example

      def print_example_request
        @output.puts example_request_title
        @output.puts example_request_attributes
        @output.puts example_request_headers
        return unless example.request_body.present?

        @output.puts example_request_body
      end

      def print_example_response
        @output.puts example_response_title

        if example.response_headers.present?
          @output.puts example_response_headers
        end

        return unless example.response_body.present?
        @output.puts example_response_body
      end

      def example_request_title
        <<-HEREDOC

+ Request #{example.request_identifier}
**#{example.request_method.upcase}**&nbsp;&nbsp;`#{CGI.unescape(example.request_fullpath)}`
        HEREDOC
      end

      def example_request_attributes
        <<-HEREDOC

    + Attributes

#{indent_lines(8, print_attributes(example.action.attrs))}
        HEREDOC
      end

      def example_request_headers
        <<-HEREDOC

    + Headers

#{indent_lines(12, print_headers(example.request_headers))}
        HEREDOC
      end

      def example_request_body
        <<-HEREDOC

    + Body

#{indent_lines(12, pretty_json(example.request_body))}
        HEREDOC
      end

      def example_response_title
        <<-HEREDOC

+ Response #{example.response_status}
        HEREDOC
      end

      def example_response_headers
        <<-HEREDOC

    + Headers

#{indent_lines(12, print_headers(example.response_headers))}
        HEREDOC
      end

      def example_response_body
        <<-HEREDOC

    + Body

#{indent_lines(12, pretty_json(safe_json_parse(example.response_body)))}
        HEREDOC
      end

      def safe_json_parse(json_string)
        json_string.length >= 2 ? JSON.parse(json_string) : nil
      end

      def pretty_json(json_string)
        if json_string.present?
          JSON.pretty_generate(json_string)
        else
          ''
        end
      end

      def print_array(arr)
        arr.collect do |arg|
          arg.kind_of?(Hash) && arg[:object] ? "- (object)#{print_array(arg[:object])}" : "- #{arg}"
        end.join("\n")
      end

      def print_description(description, attr_type)
        if attr_type.to_s == 'array' && description.kind_of?(Array)
           "\n" + indent_lines(4, print_array(description))
        elsif attr_type.to_s == 'object' && description.kind_of?(Hash) && description[:object]
          "\n" + indent_lines(4, print_array(description[:object]))
        else
          " - #{description}"
        end
      end

      def print_attributes(attrs)
        attrs.map do |attr, details|
          value = details[:value].blank? ? '' : ": `#{CGI.escape(details[:value].to_s)}`"
          type_and_required = [details[:type], details[:required]].compact
          desc = "+ #{CGI.escape(attr.to_s)}#{value} (#{type_and_required.join(', ')})"
          desc += print_description(details[:description], details[:type]) if details[:description].present?
          desc += "\n        + Default: #{details[:default]}" if details[:default].present?
          desc
        end.flatten.join("\n")
      end

      def print_headers(headers)
        headers.map do |key, value|
          "#{key}: #{value}"
        end.join("\n")
      end

      def indent_lines(number_of_spaces, string)
        string
          .split("\n")
          .map { |a| a.prepend(' ' * number_of_spaces) }
          .join("\n")
      end
    end
  end
end
