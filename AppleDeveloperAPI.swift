import Foundation

/**
 * AppleDeveloperAPI.swift
 * Chịu trách nhiệm giao tiếp với Apple Developer API để quản lý chứng chỉ và provisioning profiles.
 * Dựa trên logic từ developer_api.py trong ios_sideload_tool.zip.
 */

class AppleDeveloperAPI {
    private let session: URLSession
    private var dsid: String?
    private var sessionToken: String?
    private var teamId: String?
    private let anisetteUrl: String?

    init(anisetteUrl: String? = nil) {
        self.session = URLSession.shared
        self.anisetteUrl = anisetteUrl
    }

    func setAuth(dsid: String, sessionToken: String) {
        self.dsid = dsid
        self.sessionToken = sessionToken
    }

    func setTeam(teamId: String) {
        self.teamId = teamId
    }

    /**
     * Gửi yêu cầu đến Apple Developer API.
     */
    private func makeDeveloperRequest(action: String, params: [String: Any], completion: @escaping (Result<[String: Any], Error>) -> Void) {
        guard let dsid = dsid, let sessionToken = sessionToken else {
            completion(.failure(NSError(domain: "AppleDeveloperAPI", code: 401, userInfo: [NSLocalizedDescriptionKey: "Chưa xác thực"])))
            return
        }

        let url = URL(string: "https://developer.apple.com/services-account/QH65B2/account/\(action)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(dsid, forHTTPHeaderField: "X-Apple-DSID")
        request.addValue(sessionToken, forHTTPHeaderField: "X-Apple-Session-Token")

        // Thêm Anisette headers nếu có
        // ... (Logic lấy headers từ anisetteUrl)

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: params, options: [])
        } catch {
            completion(.failure(error))
            return
        }

        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "AppleDeveloperAPI", code: 500, userInfo: [NSLocalizedDescriptionKey: "Không có dữ liệu trả về"])))
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    completion(.success(json))
                } else {
                    completion(.failure(NSError(domain: "AppleDeveloperAPI", code: 500, userInfo: [NSLocalizedDescriptionKey: "Định dạng JSON không hợp lệ"])))
                }
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
    }

    /**
     * Liệt kê các chứng chỉ iOS Development.
     */
    func listCertificates(completion: @escaping (Result<[[String: Any]], Error>) -> Void) {
        makeDeveloperRequest(action: "ios/listDevelopmentCertificates.action", params: [:]) { result in
            switch result {
            case .success(let json):
                if let certs = json["certificates"] as? [[String: Any]] {
                    completion(.success(certs))
                } else {
                    completion(.success([]))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    /**
     * Thu hồi (revoke) một chứng chỉ.
     */
    func revokeCertificate(certificateId: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        makeDeveloperRequest(action: "ios/revokeDevelopmentCertificate.action", params: ["certificateId": certificateId]) { result in
            switch result {
            case .success(let json):
                let success = (json["resultCode"] as? Int) == 0
                completion(.success(success))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    /**
     * Tạo chứng chỉ mới (Development).
     * Yêu cầu CSR (Certificate Signing Request).
     */
    func submitDevelopmentCSR(csrContent: String, machineName: String, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        let machineId = UUID().uuidString.uppercased()
        let params: [String: Any] = [
            "csrContent": csrContent,
            "machineId": machineId,
            "machineName": machineName
        ]
        makeDeveloperRequest(action: "ios/submitDevelopmentCSR.action", params: params, completion: completion)
    }
}
