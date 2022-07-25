//
//  Extensions.swift
//  File
//
//  Created by youzy01 on 2021/9/10.
//

import UIKit

extension URL {
    func appendQueryItems(_ parameters: [String: String]?) throws -> URL {
        guard var components = URLComponents(string: absoluteString) else {
            throw RTError.invalidURL(url: absoluteString)
        }
        let items = components.queryItems ?? []
        let queryItems = parameters?.map { URLQueryItem(name: $0.key, value: $0.value) } ?? []
        components.queryItems = queryItems + items
        guard let url = components.url else {
            throw RTError.invalidURL(url: absoluteString)
        }
        return url
    }
}

// MARK: - String Extension
extension String {
    /// 是否是WebURL
    var isWebURL: Bool {
        return ["http", "https"].contains(self)
    }

    func toURL(parameters: [String: String]? = nil) throws -> URL {
        let urlString = addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        guard let url = URL(string: urlString) else {
            throw RTError.invalidURL(url: self)
        }
        return url
    }
}

// MARK: - URL Extension
extension URL {
    /// 是否是WebURL
    var isWeb: Bool {
        return ["http", "https"].contains(scheme)
    }

    /// URL携带的参数
    var queryParameters: [String: String]? {
        guard let components = URLComponents(url: self, resolvingAgainstBaseURL: true), let queryItems = components.queryItems else {
            return [:]
        }

        var parameters = [String: String]()
        for item in queryItems {
            parameters[item.name] = item.value
        }
        return parameters
    }
}

// MARK: - UIViewController Extension
extension UIViewController {
    //获取app当前最顶层的ViewController
    static var appTopVC: UIViewController? {
        var resultVC: UIViewController?
        resultVC = UIApplication.shared.windows.first(where: \.isKeyWindow)?.rootViewController?.topVC
        while resultVC?.presentedViewController != nil {
            resultVC = resultVC?.presentedViewController?.topVC
        }
        return resultVC
    }

    var topVC: UIViewController? {
        if self.isKind(of: UINavigationController.self) {
            return (self as! UINavigationController).topViewController?.topVC
        } else if self.isKind(of: UITabBarController.self) {
            return (self as! UITabBarController).selectedViewController?.topVC
        } else {
            return self
        }
    }
}
