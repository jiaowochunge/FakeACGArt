//
//  ApiClient.swift
//  BellOA2
//
//  Created by mini4 on 15/11/3.
//  Copyright © 2015年 makcoo. All rights reserved.
//

import Foundation
import Alamofire

/** http请求。采用单例 sharedApiClient 访问。构造函数为私有方法，外部无法访问
*	内部采用 HttpManager 作为真实第三方http库，方便将来替换。但这么设计好像没什么卵用，method url encode 的耦合性太强了，除非我自己也定义一套
*/
class ApiClient {
	
	/// 内部错误码
	class ResponseError {
		/// 错误域
		static let ErrorDomain = "com.makcoo.oa"
		/// 枚举错误类型
		enum ErrorCode: Int {
			/// 授权过期
			case AuthOOT = 801
			/// 返回数据格式化错误
			case RespDataFormatError = 802
			/// 服务器报错
			case ServerOperationError = 803
			/// 未知错误
			case UnknowError = 804
			
			func reason() -> String {
				switch self {
				case .AuthOOT:
					return "授权过期"
				case .RespDataFormatError:
					return "返回数据格式化错误"
				case .ServerOperationError:
					return "服务器错误"
				case .UnknowError:
					return "未知错误"
				}
			}
			
			// 服务器错误时，添加的额外错误信息
			static let ServerErrorCodeKey = "status"
			static let ServerErrorMsgKey = "message"
		}
		/// 构造错误
		class func Error(code: ErrorCode) -> NSError {
			switch code {
			case .ServerOperationError:
				assert(false, "when server error, user `ServerError` initializer")
			default:
				return NSError(domain: ErrorDomain, code: code.rawValue, userInfo: [NSLocalizedFailureReasonErrorKey: code.reason()])
			}
		}
		/// 服务器错误类型
		class func ServerError(code: Int, msg: String) -> NSError {
			return NSError(domain: ErrorDomain, code: ErrorCode.ServerOperationError.rawValue, userInfo: [NSLocalizedFailureReasonErrorKey: ErrorCode.ServerOperationError.reason(), ErrorCode.ServerErrorCodeKey: code, ErrorCode.ServerErrorMsgKey: msg])
		}
	}

	/// 真实http请求代理
	private let HttpManager: Alamofire.Manager = Alamofire.Manager.sharedInstance
	
	/// 私有化创建方法
	private init() {
		
	}
	
	/// 请求前缀
	var RootApi: String = "http://acg.sugling.in/"
	
	/// 超时时间
	var TimeoutInterval: NSTimeInterval = 30
	
	/// Cookie
	var Cookie: String = "__cfduid=da1bb5c91706698f690a549494921c43b1448936696"
		
	/// 单例
	static let sharedApiClient: ApiClient = {
		let sharedInstance = ApiClient()
		// 设置超时时间
		sharedInstance.HttpManager.session.configuration.timeoutIntervalForRequest = sharedInstance.TimeoutInterval
		return sharedInstance
	}()

	/** 定制化普通请求。请求url前缀固定为 RootApi, 超时时间固定为 TimeoutInterval, header加入token信息
	*/
//	@available(*, deprecated=1.0, message="这个方法没有对返回结果处理，请确定你要使用这个方法")
    class func request(
		method: Alamofire.Method,
		_ URLString: URLStringConvertible,
		parameters: [String: AnyObject]? = nil,
		encoding: ParameterEncoding = .URL,
		headers: [String: String]? = nil)
		-> Request
	{
		// 构造请求url
		guard let url = NSURL(string: URLString.URLString, relativeToURL: NSURL(string: sharedApiClient.RootApi)) else {
			assert(false, "construct url error")
		}
		// http请求
		let mutableURLRequest = NSMutableURLRequest(URL: url)
		// 请求方式
		mutableURLRequest.HTTPMethod = method.rawValue
		// 超时时间
		mutableURLRequest.timeoutInterval = sharedApiClient.TimeoutInterval
		
		// 添加头部信息
        mutableURLRequest.setValue(sharedApiClient.Cookie, forHTTPHeaderField: "Cookie")
        mutableURLRequest.setValue("ACGArtFree/5.2 CFNetwork/758.1.6 Darwin/15.0.0", forHTTPHeaderField: "User-Agent")

		// 添加其他头部信息
		if let headers = headers {
			for (headerField, headerValue) in headers {
				mutableURLRequest.setValue(headerValue, forHTTPHeaderField: headerField)
			}
		}
		
		// 编码参数
		let encodedURLRequest = encoding.encode(mutableURLRequest, parameters: parameters).0
		
		log.debug("request: \(encodedURLRequest)\nparameter: \(parameters)")
		// 发起请求
		return sharedApiClient.HttpManager.request(encodedURLRequest)
	}
	
	/// 定制化普通请求的基础上，定制返回格式。返回验证数据有效性，返回结构以json格式解析
	private class func request(
		method: Alamofire.Method,
		_ URLString: URLStringConvertible,
		parameters: [String: AnyObject]? = nil,
		encoding: ParameterEncoding = .JSON,
		headers: [String: String]? = nil,
		response: (Response<AnyObject, NSError> -> Void)?)
	{
		ApiClient.request(method, URLString, parameters: parameters, encoding: encoding, headers: headers).responseJSON { (responseJSON) -> Void in
			log.debug("response: \(responseJSON)")

			// 自定义处理返回结果。
			var processResponse: Response<AnyObject, NSError>!
			defer {
				response?(processResponse)
			}
			
			// 由错误信息构造错误返回结果
			func createFailResponse(error: NSError) -> Response<AnyObject, NSError> {
				return Response<AnyObject, NSError>(request: responseJSON.request, response: responseJSON.response, data: responseJSON.data, result: Result<AnyObject, NSError>.Failure(error))
			}
			// 请求失败
			if responseJSON.result.isFailure {
				log.error("response code: \(responseJSON.response?.statusCode)")
				log.error("request error: \(responseJSON.result.error)")
				processResponse = responseJSON
				return
			}
			// json 格式有效性
			guard let retDic = responseJSON.result.value as? [String: AnyObject] else {
				log.error("response data format error")
				processResponse = createFailResponse(ResponseError.Error(.RespDataFormatError))
				return
			}
			// 服务器报错
			guard let status = retDic["status"] as? Int where status == 0 else {
				guard let errorMsg = retDic["message"] as? String, let errorCode = retDic["status"] as? Int else {
					// message 或 status 不合法
					log.error("response data format error")
					processResponse = createFailResponse(ResponseError.Error(.RespDataFormatError))
					return
				}
				// 服务器报错
				log.error("server error: \(errorMsg)")
				// 构造返回值
				processResponse = createFailResponse(ResponseError.ServerError(errorCode, msg: errorMsg))
				return
			}
			guard let body = retDic["body"] else {
				// 无 body
				log.error("response data format error")
				processResponse = createFailResponse(ResponseError.Error(.RespDataFormatError))
				return
			}
			// 不应该存在其他错误
			if responseJSON.result.isFailure {
				let alert = UIAlertController(title: "fatal error", message: "how this situation happened?", preferredStyle: .Alert)
				alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
				(UIApplication.sharedApplication().delegate as! AppDelegate).window?.rootViewController?.presentViewController(alert, animated: false, completion: nil)
			}
			// 返回数据，直接解包到 body 层
			processResponse = Response<AnyObject, NSError>(request: responseJSON.request, response: responseJSON.response, data: responseJSON.data, result: Result<AnyObject, NSError>.Success(body))
		}
	}

}
