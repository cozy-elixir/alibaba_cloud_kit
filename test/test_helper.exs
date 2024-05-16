Mox.defmock(CozyAliyunOpenAPI.EasyTimeMock, for: CozyAliyunOpenAPI.EasyTimeBehaviour)
Application.put_env(:cozy_aliyun_open_api, :easy_time, CozyAliyunOpenAPI.EasyTimeMock)

Finch.start_link(name: CozyAliyunOpenAPI.Finch)

ExUnit.start()
