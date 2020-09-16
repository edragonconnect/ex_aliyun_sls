defmodule ExAliyunSls.Log do
  defmodule LogRaw.Content do
    @moduledoc false
    use Protobuf, syntax: :proto2

    @type t :: %__MODULE__{
            Key: String.t(),
            Value: binary
          }
    defstruct [:Key, :Value]

    field(:Key, 1, required: true, type: :string)
    field(:Value, 2, required: true, type: :bytes)
  end

  defmodule LogRaw do
    @moduledoc false
    use Protobuf, syntax: :proto2

    @type t :: %__MODULE__{
            Time: non_neg_integer,
            Contents: [LogRaw.Content.t()]
          }
    defstruct [:Time, :Contents]

    field(:Time, 1, required: true, type: :uint32)
    field(:Contents, 2, repeated: true, type: LogRaw.Content)
  end

  defmodule LogTagRaw do
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

  defmodule LogGroupRaw do
    @moduledoc false
    use Protobuf, syntax: :proto2

    @type t :: %__MODULE__{
            Logs: [LogRaw.t()],
            Reserved: String.t(),
            Topic: String.t(),
            Source: String.t(),
            MachineUUID: String.t(),
            LogTags: [LogTagRaw.t()]
          }
    defstruct [:Logs, :Reserved, :Topic, :Source, :MachineUUID, :LogTags]

    field(:Logs, 1, repeated: true, type: LogRaw)
    field(:Reserved, 2, optional: true, type: :string)
    field(:Topic, 3, optional: true, type: :string)
    field(:Source, 4, optional: true, type: :string)
    field(:MachineUUID, 5, optional: true, type: :string)
    field(:LogTags, 6, repeated: true, type: LogTagRaw)
  end

  defmodule LogGroupListRaw do
    @moduledoc false
    use Protobuf, syntax: :proto2

    @type t :: %__MODULE__{
            LogGroups: [LogGroupRaw.t()]
          }
    defstruct [:LogGroups]

    field(:LogGroups, 1, repeated: true, type: LogGroupRaw)
  end
end
