# credo:disable-for-this-file
[
  defmodule(ExAliyunSls.Log) do
    @moduledoc false
    (
      defstruct(Time: nil, Contents: [])

      (
        (
          @spec encode(struct) :: {:ok, iodata} | {:error, any}
          def(encode(msg)) do
            try do
              {:ok, encode!(msg)}
            rescue
              e ->
                {:error, e}
            end
          end

          @spec encode!(struct) :: iodata | no_return
          def(encode!(msg)) do
            [] |> encode_Time(msg) |> encode_Contents(msg)
          end
        )

        []

        [
          defp(encode_Time(acc, msg)) do
            case(msg."Time"()) do
              nil ->
                raise(Protox.RequiredFieldsError.new([:Time]))

              field_value ->
                [acc, "\b", Protox.Encode.encode_uint32(field_value)]
            end
          end,
          defp(encode_Contents(acc, msg)) do
            case(msg."Contents"()) do
              [] ->
                acc

              values ->
                [
                  acc,
                  Enum.reduce(values, [], fn value, acc ->
                    [acc, <<18>>, Protox.Encode.encode_message(value)]
                  end)
                ]
            end
          end
        ]

        []
      )

      (
        @spec decode(binary) :: {:ok, struct} | {:error, any}
        def(decode(bytes)) do
          try do
            {:ok, decode!(bytes)}
          rescue
            e ->
              {:error, e}
          end
        end

        (
          @spec decode!(binary) :: struct | no_return
          def(decode!(bytes)) do
            {msg, set_fields} = parse_key_value([], bytes, struct(ExAliyunSls.Log))

            case([:Time] -- set_fields) do
              [] ->
                msg

              missing_fields ->
                raise(Protox.RequiredFieldsError.new(missing_fields))
            end
          end
        )

        (
          @spec parse_key_value([atom], binary, struct) :: {struct, [atom]}
          defp(parse_key_value(set_fields, <<>>, msg)) do
            {msg, set_fields}
          end

          defp(parse_key_value(set_fields, bytes, msg)) do
            {new_set_fields, field, rest} =
              case(Protox.Decode.parse_key(bytes)) do
                {0, _, _} ->
                  raise(%Protox.IllegalTagError{})

                {1, _, bytes} ->
                  {value, rest} = Protox.Decode.parse_uint32(bytes)
                  field = {:Time, value}
                  {[:Time | set_fields], [field], rest}

                {2, _, bytes} ->
                  {len, bytes} = Protox.Varint.decode(bytes)
                  <<delimited::binary-size(len), rest::binary>> = bytes
                  value = ExAliyunSls.Log.Content.decode!(delimited)
                  field = {:Contents, msg."Contents"() ++ List.wrap(value)}
                  {[:Contents | set_fields], [field], rest}

                {tag, wire_type, rest} ->
                  {_, rest} = Protox.Decode.parse_unknown(tag, wire_type, rest)
                  {set_fields, [], rest}
              end

            msg_updated = struct(msg, field)
            parse_key_value(new_set_fields, rest, msg_updated)
          end
        )

        []
      )

      @spec defs() :: %{
              required(non_neg_integer) => {atom, Protox.Types.kind(), Protox.Types.type()}
            }
      def(defs()) do
        %{
          1 => {:Time, {:default, 0}, :uint32},
          2 => {:Contents, :unpacked, {:message, ExAliyunSls.Log.Content}}
        }
      end

      @spec defs_by_name() :: %{
              required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
            }
      def(defs_by_name()) do
        %{
          Contents: {2, :unpacked, {:message, ExAliyunSls.Log.Content}},
          Time: {1, {:default, 0}, :uint32}
        }
      end

      []
      @spec required_fields() :: [:Time]
      def(required_fields()) do
        [:Time]
      end

      @spec syntax() :: atom
      def(syntax()) do
        :proto2
      end

      [
        @spec(default(atom) :: {:ok, boolean | integer | String.t() | float} | {:error, atom}),
        def(default(:Time)) do
          {:ok, 0}
        end,
        def(default(:Contents)) do
          {:error, :no_default_value}
        end,
        def(default(_)) do
          {:error, :no_such_field}
        end
      ]
    )
  end,
  defmodule(ExAliyunSls.Log.Content) do
    @moduledoc false
    (
      defstruct(Key: nil, Value: nil)

      (
        (
          @spec encode(struct) :: {:ok, iodata} | {:error, any}
          def(encode(msg)) do
            try do
              {:ok, encode!(msg)}
            rescue
              e ->
                {:error, e}
            end
          end

          @spec encode!(struct) :: iodata | no_return
          def(encode!(msg)) do
            [] |> encode_Key(msg) |> encode_Value(msg)
          end
        )

        []

        [
          defp(encode_Key(acc, msg)) do
            case(msg."Key"()) do
              nil ->
                raise(Protox.RequiredFieldsError.new([:Key]))

              field_value ->
                [acc, "\n", Protox.Encode.encode_string(field_value)]
            end
          end,
          defp(encode_Value(acc, msg)) do
            case(msg."Value"()) do
              nil ->
                raise(Protox.RequiredFieldsError.new([:Value]))

              field_value ->
                [acc, <<18>>, Protox.Encode.encode_string(field_value)]
            end
          end
        ]

        []
      )

      (
        @spec decode(binary) :: {:ok, struct} | {:error, any}
        def(decode(bytes)) do
          try do
            {:ok, decode!(bytes)}
          rescue
            e ->
              {:error, e}
          end
        end

        (
          @spec decode!(binary) :: struct | no_return
          def(decode!(bytes)) do
            {msg, set_fields} = parse_key_value([], bytes, struct(ExAliyunSls.Log.Content))

            case([:Key, :Value] -- set_fields) do
              [] ->
                msg

              missing_fields ->
                raise(Protox.RequiredFieldsError.new(missing_fields))
            end
          end
        )

        (
          @spec parse_key_value([atom], binary, struct) :: {struct, [atom]}
          defp(parse_key_value(set_fields, <<>>, msg)) do
            {msg, set_fields}
          end

          defp(parse_key_value(set_fields, bytes, msg)) do
            {new_set_fields, field, rest} =
              case(Protox.Decode.parse_key(bytes)) do
                {0, _, _} ->
                  raise(%Protox.IllegalTagError{})

                {1, _, bytes} ->
                  {len, bytes} = Protox.Varint.decode(bytes)
                  <<delimited::binary-size(len), rest::binary>> = bytes
                  value = delimited
                  field = {:Key, value}
                  {[:Key | set_fields], [field], rest}

                {2, _, bytes} ->
                  {len, bytes} = Protox.Varint.decode(bytes)
                  <<delimited::binary-size(len), rest::binary>> = bytes
                  value = delimited
                  field = {:Value, value}
                  {[:Value | set_fields], [field], rest}

                {tag, wire_type, rest} ->
                  {_, rest} = Protox.Decode.parse_unknown(tag, wire_type, rest)
                  {set_fields, [], rest}
              end

            msg_updated = struct(msg, field)
            parse_key_value(new_set_fields, rest, msg_updated)
          end
        )

        []
      )

      @spec defs() :: %{
              required(non_neg_integer) => {atom, Protox.Types.kind(), Protox.Types.type()}
            }
      def(defs()) do
        %{1 => {:Key, {:default, ""}, :string}, 2 => {:Value, {:default, ""}, :string}}
      end

      @spec defs_by_name() :: %{
              required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
            }
      def(defs_by_name()) do
        %{Key: {1, {:default, ""}, :string}, Value: {2, {:default, ""}, :string}}
      end

      []
      @spec required_fields() :: [:Key | :Value]
      def(required_fields()) do
        [:Key, :Value]
      end

      @spec syntax() :: atom
      def(syntax()) do
        :proto2
      end

      [
        @spec(default(atom) :: {:ok, boolean | integer | String.t() | float} | {:error, atom}),
        def(default(:Key)) do
          {:ok, ""}
        end,
        def(default(:Value)) do
          {:ok, ""}
        end,
        def(default(_)) do
          {:error, :no_such_field}
        end
      ]
    )
  end,
  defmodule(ExAliyunSls.LogGroup) do
    @moduledoc false
    (
      defstruct(Logs: [], Reserved: nil, Topic: nil, Source: nil, LogTags: [])

      (
        (
          @spec encode(struct) :: {:ok, iodata} | {:error, any}
          def(encode(msg)) do
            try do
              {:ok, encode!(msg)}
            rescue
              e ->
                {:error, e}
            end
          end

          @spec encode!(struct) :: iodata | no_return
          def(encode!(msg)) do
            []
            |> encode_Logs(msg)
            |> encode_Reserved(msg)
            |> encode_Topic(msg)
            |> encode_Source(msg)
            |> encode_LogTags(msg)
          end
        )

        []

        [
          defp(encode_Logs(acc, msg)) do
            case(msg."Logs"()) do
              [] ->
                acc

              values ->
                [
                  acc,
                  Enum.reduce(values, [], fn value, acc ->
                    [acc, "\n", Protox.Encode.encode_message(value)]
                  end)
                ]
            end
          end,
          defp(encode_Reserved(acc, msg)) do
            field_value = msg."Reserved"()

            case(field_value) do
              nil ->
                acc

              _ ->
                [acc, <<18>>, Protox.Encode.encode_string(field_value)]
            end
          end,
          defp(encode_Topic(acc, msg)) do
            field_value = msg."Topic"()

            case(field_value) do
              nil ->
                acc

              _ ->
                [acc, <<26>>, Protox.Encode.encode_string(field_value)]
            end
          end,
          defp(encode_Source(acc, msg)) do
            field_value = msg."Source"()

            case(field_value) do
              nil ->
                acc

              _ ->
                [acc, "\"", Protox.Encode.encode_string(field_value)]
            end
          end,
          defp(encode_LogTags(acc, msg)) do
            case(msg."LogTags"()) do
              [] ->
                acc

              values ->
                [
                  acc,
                  Enum.reduce(values, [], fn value, acc ->
                    [acc, "2", Protox.Encode.encode_message(value)]
                  end)
                ]
            end
          end
        ]

        []
      )

      (
        @spec decode(binary) :: {:ok, struct} | {:error, any}
        def(decode(bytes)) do
          try do
            {:ok, decode!(bytes)}
          rescue
            e ->
              {:error, e}
          end
        end

        (
          @spec decode!(binary) :: struct | no_return
          def(decode!(bytes)) do
            parse_key_value(bytes, struct(ExAliyunSls.LogGroup))
          end
        )

        (
          @spec parse_key_value(binary, struct) :: struct
          defp(parse_key_value(<<>>, msg)) do
            msg
          end

          defp(parse_key_value(bytes, msg)) do
            {field, rest} =
              case(Protox.Decode.parse_key(bytes)) do
                {0, _, _} ->
                  raise(%Protox.IllegalTagError{})

                {1, _, bytes} ->
                  {len, bytes} = Protox.Varint.decode(bytes)
                  <<delimited::binary-size(len), rest::binary>> = bytes
                  value = ExAliyunSls.Log.decode!(delimited)
                  field = {:Logs, msg."Logs"() ++ List.wrap(value)}
                  {[field], rest}

                {2, _, bytes} ->
                  {len, bytes} = Protox.Varint.decode(bytes)
                  <<delimited::binary-size(len), rest::binary>> = bytes
                  value = delimited
                  field = {:Reserved, value}
                  {[field], rest}

                {3, _, bytes} ->
                  {len, bytes} = Protox.Varint.decode(bytes)
                  <<delimited::binary-size(len), rest::binary>> = bytes
                  value = delimited
                  field = {:Topic, value}
                  {[field], rest}

                {4, _, bytes} ->
                  {len, bytes} = Protox.Varint.decode(bytes)
                  <<delimited::binary-size(len), rest::binary>> = bytes
                  value = delimited
                  field = {:Source, value}
                  {[field], rest}

                {6, _, bytes} ->
                  {len, bytes} = Protox.Varint.decode(bytes)
                  <<delimited::binary-size(len), rest::binary>> = bytes
                  value = ExAliyunSls.LogTag.decode!(delimited)
                  field = {:LogTags, msg."LogTags"() ++ List.wrap(value)}
                  {[field], rest}

                {tag, wire_type, rest} ->
                  {_, rest} = Protox.Decode.parse_unknown(tag, wire_type, rest)
                  {[], rest}
              end

            msg_updated = struct(msg, field)
            parse_key_value(rest, msg_updated)
          end
        )

        []
      )

      @spec defs() :: %{
              required(non_neg_integer) => {atom, Protox.Types.kind(), Protox.Types.type()}
            }
      def(defs()) do
        %{
          1 => {:Logs, :unpacked, {:message, ExAliyunSls.Log}},
          2 => {:Reserved, {:default, ""}, :string},
          3 => {:Topic, {:default, ""}, :string},
          4 => {:Source, {:default, ""}, :string},
          6 => {:LogTags, :unpacked, {:message, ExAliyunSls.LogTag}}
        }
      end

      @spec defs_by_name() :: %{
              required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
            }
      def(defs_by_name()) do
        %{
          LogTags: {6, :unpacked, {:message, ExAliyunSls.LogTag}},
          Logs: {1, :unpacked, {:message, ExAliyunSls.Log}},
          Reserved: {2, {:default, ""}, :string},
          Source: {4, {:default, ""}, :string},
          Topic: {3, {:default, ""}, :string}
        }
      end

      []
      @spec required_fields() :: []
      def(required_fields()) do
        []
      end

      @spec syntax() :: atom
      def(syntax()) do
        :proto2
      end

      [
        @spec(default(atom) :: {:ok, boolean | integer | String.t() | float} | {:error, atom}),
        def(default(:Logs)) do
          {:error, :no_default_value}
        end,
        def(default(:Reserved)) do
          {:ok, ""}
        end,
        def(default(:Topic)) do
          {:ok, ""}
        end,
        def(default(:Source)) do
          {:ok, ""}
        end,
        def(default(:LogTags)) do
          {:error, :no_default_value}
        end,
        def(default(_)) do
          {:error, :no_such_field}
        end
      ]
    )
  end,
  defmodule(ExAliyunSls.LogGroupList) do
    @moduledoc false
    (
      defstruct(logGroupList: [])

      (
        (
          @spec encode(struct) :: {:ok, iodata} | {:error, any}
          def(encode(msg)) do
            try do
              {:ok, encode!(msg)}
            rescue
              e ->
                {:error, e}
            end
          end

          @spec encode!(struct) :: iodata | no_return
          def(encode!(msg)) do
            [] |> encode_logGroupList(msg)
          end
        )

        []

        [
          defp(encode_logGroupList(acc, msg)) do
            case(msg.logGroupList()) do
              [] ->
                acc

              values ->
                [
                  acc,
                  Enum.reduce(values, [], fn value, acc ->
                    [acc, "\n", Protox.Encode.encode_message(value)]
                  end)
                ]
            end
          end
        ]

        []
      )

      (
        @spec decode(binary) :: {:ok, struct} | {:error, any}
        def(decode(bytes)) do
          try do
            {:ok, decode!(bytes)}
          rescue
            e ->
              {:error, e}
          end
        end

        (
          @spec decode!(binary) :: struct | no_return
          def(decode!(bytes)) do
            parse_key_value(bytes, struct(ExAliyunSls.LogGroupList))
          end
        )

        (
          @spec parse_key_value(binary, struct) :: struct
          defp(parse_key_value(<<>>, msg)) do
            msg
          end

          defp(parse_key_value(bytes, msg)) do
            {field, rest} =
              case(Protox.Decode.parse_key(bytes)) do
                {0, _, _} ->
                  raise(%Protox.IllegalTagError{})

                {1, _, bytes} ->
                  {len, bytes} = Protox.Varint.decode(bytes)
                  <<delimited::binary-size(len), rest::binary>> = bytes
                  value = ExAliyunSls.LogGroup.decode!(delimited)
                  field = {:logGroupList, msg.logGroupList() ++ List.wrap(value)}
                  {[field], rest}

                {tag, wire_type, rest} ->
                  {_, rest} = Protox.Decode.parse_unknown(tag, wire_type, rest)
                  {[], rest}
              end

            msg_updated = struct(msg, field)
            parse_key_value(rest, msg_updated)
          end
        )

        []
      )

      @spec defs() :: %{
              required(non_neg_integer) => {atom, Protox.Types.kind(), Protox.Types.type()}
            }
      def(defs()) do
        %{1 => {:logGroupList, :unpacked, {:message, ExAliyunSls.LogGroup}}}
      end

      @spec defs_by_name() :: %{
              required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
            }
      def(defs_by_name()) do
        %{logGroupList: {1, :unpacked, {:message, ExAliyunSls.LogGroup}}}
      end

      []
      @spec required_fields() :: []
      def(required_fields()) do
        []
      end

      @spec syntax() :: atom
      def(syntax()) do
        :proto2
      end

      [
        @spec(default(atom) :: {:ok, boolean | integer | String.t() | float} | {:error, atom}),
        def(default(:logGroupList)) do
          {:error, :no_default_value}
        end,
        def(default(_)) do
          {:error, :no_such_field}
        end
      ]
    )
  end,
  defmodule(ExAliyunSls.LogTag) do
    @moduledoc false
    (
      defstruct(Key: nil, Value: nil)

      (
        (
          @spec encode(struct) :: {:ok, iodata} | {:error, any}
          def(encode(msg)) do
            try do
              {:ok, encode!(msg)}
            rescue
              e ->
                {:error, e}
            end
          end

          @spec encode!(struct) :: iodata | no_return
          def(encode!(msg)) do
            [] |> encode_Key(msg) |> encode_Value(msg)
          end
        )

        []

        [
          defp(encode_Key(acc, msg)) do
            case(msg."Key"()) do
              nil ->
                raise(Protox.RequiredFieldsError.new([:Key]))

              field_value ->
                [acc, "\n", Protox.Encode.encode_string(field_value)]
            end
          end,
          defp(encode_Value(acc, msg)) do
            case(msg."Value"()) do
              nil ->
                raise(Protox.RequiredFieldsError.new([:Value]))

              field_value ->
                [acc, <<18>>, Protox.Encode.encode_string(field_value)]
            end
          end
        ]

        []
      )

      (
        @spec decode(binary) :: {:ok, struct} | {:error, any}
        def(decode(bytes)) do
          try do
            {:ok, decode!(bytes)}
          rescue
            e ->
              {:error, e}
          end
        end

        (
          @spec decode!(binary) :: struct | no_return
          def(decode!(bytes)) do
            {msg, set_fields} = parse_key_value([], bytes, struct(ExAliyunSls.LogTag))

            case([:Key, :Value] -- set_fields) do
              [] ->
                msg

              missing_fields ->
                raise(Protox.RequiredFieldsError.new(missing_fields))
            end
          end
        )

        (
          @spec parse_key_value([atom], binary, struct) :: {struct, [atom]}
          defp(parse_key_value(set_fields, <<>>, msg)) do
            {msg, set_fields}
          end

          defp(parse_key_value(set_fields, bytes, msg)) do
            {new_set_fields, field, rest} =
              case(Protox.Decode.parse_key(bytes)) do
                {0, _, _} ->
                  raise(%Protox.IllegalTagError{})

                {1, _, bytes} ->
                  {len, bytes} = Protox.Varint.decode(bytes)
                  <<delimited::binary-size(len), rest::binary>> = bytes
                  value = delimited
                  field = {:Key, value}
                  {[:Key | set_fields], [field], rest}

                {2, _, bytes} ->
                  {len, bytes} = Protox.Varint.decode(bytes)
                  <<delimited::binary-size(len), rest::binary>> = bytes
                  value = delimited
                  field = {:Value, value}
                  {[:Value | set_fields], [field], rest}

                {tag, wire_type, rest} ->
                  {_, rest} = Protox.Decode.parse_unknown(tag, wire_type, rest)
                  {set_fields, [], rest}
              end

            msg_updated = struct(msg, field)
            parse_key_value(new_set_fields, rest, msg_updated)
          end
        )

        []
      )

      @spec defs() :: %{
              required(non_neg_integer) => {atom, Protox.Types.kind(), Protox.Types.type()}
            }
      def(defs()) do
        %{1 => {:Key, {:default, ""}, :string}, 2 => {:Value, {:default, ""}, :string}}
      end

      @spec defs_by_name() :: %{
              required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
            }
      def(defs_by_name()) do
        %{Key: {1, {:default, ""}, :string}, Value: {2, {:default, ""}, :string}}
      end

      []
      @spec required_fields() :: [:Key | :Value]
      def(required_fields()) do
        [:Key, :Value]
      end

      @spec syntax() :: atom
      def(syntax()) do
        :proto2
      end

      [
        @spec(default(atom) :: {:ok, boolean | integer | String.t() | float} | {:error, atom}),
        def(default(:Key)) do
          {:ok, ""}
        end,
        def(default(:Value)) do
          {:ok, ""}
        end,
        def(default(_)) do
          {:error, :no_such_field}
        end
      ]
    )
  end
]
