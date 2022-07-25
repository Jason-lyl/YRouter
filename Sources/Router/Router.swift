//
//  Router.swift
//  File
//
//  Created by youzy01 on 2021/9/10.
//

import UIKit

/// 路由配置
public struct RouterConfiguration {
    /// APP的 scheme
    public var scheme = ""
    /// App 的 host
    public var host = ""

    /// 是否进行权限判断
    public var isAuthorize: Bool = true

    /// 是否已登录，默认false
    public var isLogin: (() -> Bool) = { false }
    /// 是否已创建成绩，默认false
    public var isScore: (() -> Bool) = { false }

    /// WebView的路由路径
    public var webView: Router.Path?
    /// 登录页面的路由路径
    public var login: Router.Path?
    /// 创建成绩页面的路由路径
    public var score: Router.Path?

    /// 是否已创建文化成绩，默认true
    /// 优艺考需要校验 其他项目暂时不需要
    public var isCultureScore: (() -> Bool) = { true }
    /// 优艺考文化成绩路径
    public var cultureScore: Router.Path?

    public init() {}
}

extension Router {
    /// 路由实体
    struct Entity {
        var path: Path
        var parameters: [String: String]?
    }
}

public extension Router {
    /// 预定义key
    enum Key {
        /// webURL
        public static let url = "url"
        /// 路由URL
        public static let routerUrl = "routerUrl"
    }
}

/// 路由
public final class Router {
    /// 单例
    private static var shared: Router!

    /// 配置
    private let configuration: RouterConfiguration
    /// 路由表
    private let hashMap: [Router.Path: UnsafePointer<CChar>]

    /// 初始化方法
    /// - Parameters:
    ///   - configuration: 配置
    ///   - hashMap: 路由表
    private init(configuration: RouterConfiguration, hashMap: [Router.Path: UnsafePointer<CChar>]) {
        self.configuration = configuration
        self.hashMap = hashMap
    }

    /// 初始化路由
    ///
    /// 必须调用此方法，否则`shared`为空
    ///
    /// - Parameters:
    ///   - configuration: 配置
    ///   - className: `类`类型, 用于自动获取遵守路由协议的类
    public static func initialize(with configuration: RouterConfiguration, className: AnyClass?) {
        let hashMap = Utils.hashMap(className)
        shared = Router(configuration: configuration, hashMap: hashMap)
    }

    /// 执行Action代表的动作
    /// - Parameters:
    ///   - action: 请看 Router.Action
    ///   - parameters: 自定义参数
    ///   - vc: 调用转场方法的控制器
    public static func open(action: Router.Action, parameters: [String: String]? = nil, form vc: UIViewController? = nil) {
        switch action {
        case .scheme(let scheme):
            scheme.run()
        case .url(let url):
            open(url: url, parameters: parameters, form: vc)
        case .class(let classType):
            open(classType: classType, parameter: parameters, form: vc)
        }
    }

    /// 打开URL目标
    /// - Parameters:
    ///   - url: 路由URL
    ///   - parameters: 自定义参数
    ///   - vc: 调用转场方法的控制器
    static func open(url: String, parameters: [String: String]? = nil, form vc: UIViewController? = nil) {
        assert(shared != nil, "请在APP启动时调用 `initialize(with:className:) 方法初始化`")

        do {
            let url = try url.toURL()
            let entity = try shared.creatEntity(url: url, parameters: parameters)
            shared.openMethod(entity: entity, from: vc)
        } catch {
            debugPrint("Router Error", error.localizedDescription)
        }
    }

    /// 打开符合路由协议的类
    /// - Parameters:
    ///   - classType: 类类型
    ///   - parameter: 自定义参数
    ///   - vc: 调用转场方法的控制器
    static func open(classType: Routable.Type, parameter: [String: String]? = nil, form vc: UIViewController? = nil) {
        assert(shared != nil, "请在APP启动时调用 `initialize(with:className:) 方法初始化`")
        var url = shared.configuration.scheme
        url += "://"
        url += shared.configuration.host
        url += ":"
        url += "\(classType.port.rawValue)"
        url += classType.path.rawValue

        if let query = parameter?.map({ "\($0.key)=\($0.value)" }).joined(separator: "&") {
            url += "?"
            url += query
        }

        Router.open(url: url, parameters: nil, form: vc)
    }
}

extension Router {
    /// 创建路由实体
    /// - Parameter url: 路由URL
    /// - Returns: 一个`webView`/`login`/`score`实体
    func creatEntity(url: URL, parameters: [String: String]?) throws -> Entity {

        // 验证scheme是否合规
        guard url.scheme == configuration.scheme else {
            if url.isWeb {
                return try Utils.webEntity(url: url, configuration: configuration)
            }
            throw RTError.verificationFailed(reason: .scheme(url: url))
        }

        // 验证域名是否合规
        guard let host = url.host, host == configuration.host else {
            throw RTError.verificationFailed(reason: .host(url: url))
        }

        // 通过
        if let entity = try authorizeEntity(url: url, parameters: parameters, configuration: configuration) {
            return entity
        }

        let path = Path(rawValue: url.path)

        let parameters = url.queryParameters?.merging(parameters ?? [:], uniquingKeysWith: +)
        return Entity(path: path, parameters: parameters)
    }

    /// 权限判断
    ///
    /// 权限通过验证则返回Nil
    ///
    /// - Parameters:
    ///   - url: 路由URL
    ///   - configuration: 配置
    /// - Returns: 登录或创建成绩的路由
    func authorizeEntity(url: URL, parameters: [String: String]?, configuration: RouterConfiguration) throws -> Entity? {
        guard configuration.isAuthorize else { return nil }

        // port 300 判断
        if case .login = Port(rawValue: url.port ?? 0), !configuration.isLogin() {
            let newURL = try url.appendQueryItems(parameters)
            return try Utils.loginEntity(url: newURL, configuration: configuration)
        } else if case .score = Port(rawValue: url.port ?? 0) { // port 400 判断
            if !configuration.isLogin() {
                return try Utils.loginEntity(url: url, configuration: configuration)
            } else if !configuration.isScore() {
                if let path = configuration.score {
                    return Entity(path: path, parameters: nil)
                }
                throw RTError.authorityFailed(reason: .scorePathIsNil(url: url))
            } else if !configuration.isCultureScore() {
                if let path = configuration.cultureScore {
                    return Entity(path: path, parameters: nil)
                }
            }
        }
        return nil
    }

    /// 跳转方法
    /// - Parameters:
    ///   - entity: 路由实体
    ///   - vc: 调用转场方法的控制器
    func openMethod(entity: Entity, from vc: UIViewController?) {
        guard let classType = classType(for: entity.path) else {
            return
        }

        guard let classValue = classType.creat(with: entity.parameters) else {
            return
        }
        classValue.hidesBottomBarWhenPushed = true

        guard let controller = vc ?? UIViewController.appTopVC else {
            return
        }

        switch classType.transition {
        case .push(let animated):
            controller.navigationController?.pushViewController(classValue, animated: animated)
        case .present(let animated):
            controller.present(classValue, animated: animated, completion: nil)
        }
    }

    /// 使用路径获取目标类名
    /// - Parameter path: 路径
    /// - Returns: 类名
    func classType(for path: Path) -> Routable.Type? {
        guard let cString = hashMap[path] else {
            return nil
        }
        return objc_getRequiredClass(cString) as? Routable.Type
    }
}
