Pod::Spec.new do |s|
  s.name             = 'ZHHChatKeyboard'
  s.version          = '1.0.0'
  s.summary          = '纯 Swift 仿微信聊天输入栏：键盘/表情/扩展面板平滑切换。'
  s.description      = <<-DESC
ZHHChatKeyboard：常驻 / 弹出聊天输入条、标准与胶囊布局、表情图文互转、
扩展面板，以及键盘 / 面板状态机防抖动。
                       DESC
  s.homepage         = 'https://github.com/yue5yueliang/ZHHChatKeyboard'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { '桃色三岁' => '136769890@qq.com' }
  s.source           = { :git => 'https://github.com/yue5yueliang/ZHHChatKeyboard.git', :tag => s.version.to_s }

  s.ios.deployment_target = '15.0'
  s.swift_version = '5.0'
  s.frameworks = 'UIKit', 'Foundation'

  s.source_files = 'ZHHChatKeyboard/Classes/**/*'
  s.resource_bundles = {
    'ZHHChatKeyboard' => ['ZHHChatKeyboard/Assets/**/*', 'ZHHChatKeyboard/PrivacyInfo.xcprivacy']
  }
end
