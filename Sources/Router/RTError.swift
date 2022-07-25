//
//  RTError.swift
//  File
//
//  Created by youzy01 on 2021/9/10.
//

import Foundation

/// 路由错误
enum RTError: Error {
    /// 无效的URL
    case invalidURL(url: String)

    enum VerificationReason {
        case scheme(url: URL)
        case host(url: URL)
    }

    /// URL验证失败
    case verificationFailed(reason: VerificationReason)
    /// webView路径发生错误
    case webPathIsNil(url: URL)

    enum AuthorityReason {
        case loginPathIsNil(url: URL)
        case scorePathIsNil(url: URL)
    }

    /// 权限错误
    case authorityFailed(reason: AuthorityReason)
}

extension RTError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case let .invalidURL(url):
            return "URL is not valid: \(url)"
        case let .verificationFailed(reason):
            return reason.localizedDescription
        case let .webPathIsNil(url):
            return "WebView路径为空 \(url)"
        case let .authorityFailed(reason):
            return reason.localizedDescription
        }
    }
}

extension RTError.VerificationReason {
    var localizedDescription: String {
        switch self {
        case let .scheme(url):
            return "URL Scheme 验证失败 \(url)"
        case let .host(url):
            return "URL Host 验证失败 \(url)"
        }
    }
}

extension RTError.AuthorityReason {
    var localizedDescription: String {
        switch self {
        case let .loginPathIsNil(url):
            return "登录页面路径为空 \(url)"
        case let .scorePathIsNil(url):
            return "成绩页面路径为空 \(url)"
        }
    }
}
