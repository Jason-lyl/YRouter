//
//  File.swift
//  File
//
//  Created by youzy01 on 2021/9/10.
//

import Foundation

class Utils {
    static func hashMap(_ className: AnyClass?) -> [Router.Path: UnsafePointer<CChar>] {
        var result: [Router.Path: UnsafePointer<CChar>] = [:]

        var count: UInt32 = 0
        guard let imageName = class_getImageName(className) else {
            return result
        }

        guard let classNames = objc_copyClassNamesForImage(imageName, &count) else {
            return result
        }

        (0..<Int(count)).forEach { idx in
            let cString = classNames[idx]
            guard let classValue = objc_lookUpClass(cString) as? Routable.Type else {
                return
            }
            result[classValue.path] = cString
        }
        return result
    }

    static func webEntity(url: URL, configuration: RouterConfiguration) throws -> Router.Entity {
        guard let path = configuration.webView else {
            throw RTError.webPathIsNil(url: url)
        }
        let urlValue = url.absoluteString.removingPercentEncoding ?? ""
        return Router.Entity(path: path, parameters: [Router.Key.url: urlValue])
    }

    static func loginEntity(url: URL, configuration: RouterConfiguration) throws -> Router.Entity {
        guard let path = configuration.login else {
            throw RTError.authorityFailed(reason: .loginPathIsNil(url: url))
        }
        let urlValue = url.absoluteString.removingPercentEncoding ?? ""
        return Router.Entity(path: path, parameters: [Router.Key.routerUrl: urlValue])
    }
}
