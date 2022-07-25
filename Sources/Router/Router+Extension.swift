//
//  File.swift
//  File
//
//  Created by youzy01 on 2021/9/10.
//

import UIKit

public extension Router {
    /// 路径
    struct Path: RawRepresentable, Hashable {
        public var rawValue: String

        public init(rawValue: String) {
            self.rawValue = rawValue
        }
    }

    /// URL端口
    ///
    /// 判断路由目标是否需要授权
    enum Port: Int {
        /// 无限制
        case none = 200
        /// 须登录
        case login = 300
        /// 需成绩
        case score = 400
        /// 需VIP
        case vip = 403
    }

    /// 转场方式
    enum Transition {
        case push(animated: Bool)
        case present(animated: Bool)
    }
}

public extension Router {
    enum Action {
        case scheme(Scheme)
        case url(String)
        case `class`(Routable.Type)
    }
}

public extension Router.Action {
    enum Scheme {
        case tel(String)
        case setting
        case app(String)

        func run() {
            var scheme: String
            switch self {
            case .tel(let phone):
                scheme = "tel://" + phone
            case .setting:
                scheme = UIApplication.openSettingsURLString
            case .app(let url):
                scheme = url
            }
            let url = URL(string: scheme)!
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
}
