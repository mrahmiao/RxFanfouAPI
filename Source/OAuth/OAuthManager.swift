//
//  OAuthManager.swift
//  RxFanfouAPI
//
//  Created by mrahmiao on 4/22/16.
//  Copyright © 2016 EWStudio. All rights reserved.
//

import Foundation
import Moya
import Result

/**
 *  饭否第三方应用的用于获取授权的元数据
 */
public struct ConsumerCredential {
  public let key: String
  public let secret: String
  public let callbackURL: String
}

/**
 *  饭否第三方应用获得授权后的Token
 */
public struct TokenCredential {

  // 请求返回的字符串中相关数据的key值
  private let oauthTokenKey = "oauth_token"
  private let oauthTokenSecretKey = "oauth_token_secret"
  private let accessTokenKey = "access_token"
  private let accessTokenSecretKey = "access_token_secret"

  public static let DefaultTokenIdentifier = "com.ewstudio.RxFanfouAPI.DefaultTokenIdentifier"

  public let identifier: String

  public let oauthToken: String
  public let oauthTokenSecret: String

  public private(set) var accessToken: String?
  public private(set) var accessTokenSecret: String?

  public init(oauthToken: String, oauthTokenSecret: String, identifier: String = TokenCredential.DefaultTokenIdentifier) {
    self.identifier = identifier

    self.oauthToken = oauthToken
    self.oauthTokenSecret = oauthTokenSecret
    self.accessToken = nil
    self.accessTokenSecret = nil
  }

  init?(query: String, identifier: String = TokenCredential.DefaultTokenIdentifier) {
    guard let params = query.ffa_queryParamaters else {
      return nil
    }

    guard let token = params[oauthTokenKey], secret = params[oauthTokenSecretKey] else {
      return nil
    }

    self.oauthToken = token
    self.oauthTokenSecret = secret

    self.identifier = identifier
  }
}

/**
 授权类型

 - Mobile:  移动端
 - Desktop: 桌面
 */
public enum AuthorizationType: String {
  case Mobile = "http://m.fanfou.com/oauth/authorize?oauth_token=%@&oauth_callback=%@"
  case Desktop = "http://fanfou.com/oauth/authorize?oauth_token=%@&oauth_callback=%@"
}

/**
 *  OAuthManager负责处理OAuth相关的请求
 */
struct OAuthManager {
  private let consumerCredential: ConsumerCredential
  private let authorizationType: AuthorizationType
  private let provider = MoyaProvider<API.OAuth>()

  func requestAuthorization(completion: Result<(TokenCredential, NSURL), Moya.Error> -> Void) {
    provider.request(.RequestToken(consumerCredential)) { result in
      switch result {
      case .Success(let response):

        let query: String

        do {
          query = try response.filterSuccessfulStatusCodes().mapString()
        } catch {
          completion(.Failure(.Underlying(error)))
          return
        }

        guard let credential = TokenCredential(query: query) else {
          completion(.Failure(.Underlying(APIErrors.IncorrectQueryString(query))))
          return
        }

        let URL = NSURL(string: String(format: self.authorizationType.rawValue, credential.oauthTokenSecret, self.consumerCredential.callbackURL))!
        completion(.Success((credential, URL)))

      case .Failure(let error):
        completion(.Failure(error))
      }
    }
  }

  func requestAccessToken(completion: Result<(TokenCredential, NSURL), Moya.Error> -> Void) {

  }
}