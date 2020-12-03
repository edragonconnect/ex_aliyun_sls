defmodule ExAliyunSls do
  defmodule Log.Content do
    @moduledoc false
    use Protobuf, syntax: :proto2

    @type t :: %__MODULE__{
            Key: String.t(),
            Value: String.t()
          }
    defstruct [:Key, :Value]

    field(:Key, 1, required: true, type: :string)
    field(:Value, 2, required: true, type: :string)
  end

  defmodule Log do
    @moduledoc false
    use Protobuf, syntax: :proto2

    @type t :: %__MODULE__{
            Time: non_neg_integer,
            Contents: [Log.Content.t()]
          }
    defstruct [:Time, :Contents]

    field(:Time, 1, required: true, type: :uint32)
    field(:Contents, 2, repeated: true, type: Log.Content)
  end

  defmodule LogTag do
    @moduledoc false
    use Protobuf, syntax: :proto2

    @type t :: %__MODULE__{
            Key: String.t(),
            Value: String.t()
          }
    defstruct [:Key, :Value]

    field(:Key, 1, required: true, type: :string)
    field(:Value, 2, required: true, type: :string)
  end

  defmodule LogGroup do
    @moduledoc false
    use Protobuf, syntax: :proto2

    @type t :: %__MODULE__{
            Logs: [Log.t()],
            Reserved: String.t(),
            Topic: String.t(),
            Source: String.t(),
            LogTags: [LogTag.t()]
          }
    defstruct [:Logs, :Reserved, :Topic, :Source, :LogTags]

    field(:Logs, 1, repeated: true, type: Log)
    field(:Reserved, 2, optional: true, type: :string)
    field(:Topic, 3, optional: true, type: :string)
    field(:Source, 4, optional: true, type: :string)
    field(:LogTags, 6, repeated: true, type: LogTag)
  end

  defmodule LogGroupList do
    @moduledoc false
    use Protobuf, syntax: :proto2

    @type t :: %__MODULE__{
            logGroupList: [LogGroup.t()]
          }
    defstruct [:logGroupList]

    field(:logGroupList, 1, repeated: true, type: LogGroup)
  end
end
