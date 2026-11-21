Pod::Spec.new do |s|
  s.name             = 'ZHHChatKeyboard'
  s.version          = '1.0.0'
  s.summary          = '纯 Swift 聊天输入栏：键盘 / 表情 / 扩展面板平滑切换。'

  s.description      = <<-DESC
ZHHChatKeyboard 提供与业务解耦的聊天底部输入能力：常驻 / 弹出输入条、
标准与胶囊布局、表情图文互转、扩展面板，以及键盘 / 面板状态机防抖动。
输入框为轻量 ChatInputTextView（占位、字数、表情插删）；面板与资源可配。
                       DESC

  s.homepage         = 'https://github.com/yue5yueliang/ZHHChatKeyboard'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { '桃色三岁' => '136769890@qq.com' }
  s.source           = { :git => 'https://github.com/yue5yueliang/ZHHChatKeyboard.git', :tag => s.version.to_s }

  s.ios.deployment_target = '15.0'
  s.swift_versions = ['5.5']
  s.frameworks = 'UIKit', 'Foundation'

  # 隐私清单 + 默认图标 / 色板；resource_bundles 避免覆盖宿主 App 清单
  s.resource_bundles = {
    'ZHHChatKeyboard' => ['ZHHChatKeyboard/Assets/**/*', 'ZHHChatKeyboard/PrivacyInfo.xcprivacy']
  }

  # 默认 Source subspec：Development Pods 里单独一组源码树
  s.default_subspec = 'Source'

  s.subspec 'Source' do |ss|
    ss.source_files = 'ZHHChatKeyboard/Classes/**/*'
  end
end
