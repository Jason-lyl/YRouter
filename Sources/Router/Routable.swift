//
//  File.swift
//  File
//
//  Created by youzy01 on 2021/9/10.
//

import UIKit

/// 路由协议
public protocol Routable {
    /// 页面路径
    static var path: Router.Path { get }

    /// 需要的权限
    static var port: Router.Port { get }

    /// 转场方式
    static var transition: Router.Transition { get }

    /// 创建控制器
    static func creat(with parameters: [String: String]?) -> UIViewController?
}
