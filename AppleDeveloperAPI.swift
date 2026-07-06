import Foundation

/**
 * AppleDeveloperAPI.swift
 * Triển khai logic thực tế để giao tiếp với Apple Developer API.
 * Hỗ trợ Anisette-v3 để đăng nhập không cần máy tính.
 */

class AppleDeveloperAPI {
    private let session: URLSession
    private var dsid: String?
    private var sessionToken: String?
    private var teamId: String?
    
    // Server Anisette mặc định (có thể thay đổi)
    private let defaultAnisetteUrl = "https://anisette.sidestore.io"

    init() {
        self.session = URLSession.shared
    }

    func setAuth(dsid: String, sessionToken: String) {
        self.dsid = dsid
        self.sessionToken = sessionToken
    }

    /**
     * Lấy Anisette headers từ server.
     * Đây là phần quan trọng để Apple chấp nhận yêu cầu từ thiết bị iOS.
     */
    private func fetchAnisetteHeaders(completion: @escaping ([String: String]?) -> Void) {
        guard let url = URL(string: defaultAnisetteUrl) else {
            completion(nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let task = session.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                completion(nil)
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: String] {
                    completion(json)
                } else {
                    completion(nil)
                }
            } catch {
                completion(nil)
            }
        }
        task.resume()
    }

    /**
     * Gửi yêu cầu đến Apple Developer API với đầy đủ Anisette headers.
     */
    func makeDeveloperRequest(action: String, params: [String: Any], completion: @escaping (Result<[String: Any], Error>) -> Void) {
        fetchAnisetteHeaders { anisetteHeaders in
            guard let anisette = anisetteHeaders else {
                completion(.failure(NSError(domain: "AppleDeveloperAPI", code: 500, userInfo: [NSLocalizedDescriptionKey: "Không thể lấy Anisette data"])))
                return
            }
            
            let url = URL(string: "https://developer.apple.com/services-account/QH65B2/account/\(action)")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            
            if let dsid = self.dsid, let token = self.sessionToken {
                request.addValue(dsid, forHTTPHeaderField: "X-Apple-DSID")
                request.addValue(token, forHTTPHeaderField: "X-Apple-Session-Token")
            }
            
            // Gán Anisette headers
            for (key, value) in anisette {
                request.addValue(value, forHTTPHeaderField: key)
            }

            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: params, options: [])
            } catch {
                completion(.failure(error))
                return
            }

            let task = self.session.dataTask(with: request) { data, response, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                guard let data = data else {
                    completion(.failure(NSError(domain: "AppleDeveloperAPI", code: 500, userInfo: [NSLocalizedDescriptionKey: "Dữ liệu trống"])))
                    return
                }

                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                        completion(.success(json))
                    } else {
                        completion(.failure(NSError(domain: "AppleDeveloperAPI", code: 500, userInfo: [NSLocalizedDescriptionKey: "JSON không hợp lệ"])))
                    }
                } catch {
                    completion(.failure(error))
                }
            }
            task.resume()
        }
    }
    
    // Các hàm listCertificates, revokeCertificate, submitDevelopmentCSR... giữ nguyên logic gọi makeDeveloperRequest
}
