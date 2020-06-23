/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Set up connection options for secure TLS connections and listeners.
*/

import Foundation
import Network
import CryptoKit

public enum ConnectionOptions {
    public enum TCP {
        public static var options: NWProtocolTCP.Options {
            let options = NWProtocolTCP.Options()
            options.noDelay = true
            return options
        }
    }
    
    public enum TLS {
        public enum Error: Swift.Error {
            case invalidP12
            case unableToExtractIdentity
            case unknown
        }
        
        public class Server {
            public let p12: URL
            public let passphrase: String
            
            public init(p12 url: URL, passphrase: String) {
                self.p12 = url
                self.passphrase = passphrase
            }
            
            public var options: NWProtocolTLS.Options? {
                guard let data = try? Data(contentsOf: p12) else {
                    return nil
                }
                
                let pkcs12Options = [ kSecImportExportPassphrase: passphrase ]
                var importItems: CFArray?
                let status = SecPKCS12Import(data as CFData, pkcs12Options as CFDictionary, &importItems)
                
                guard status == errSecSuccess,
                    let items = importItems as? [[String: Any]],
                    let importItemIdentity = items.first?[kSecImportItemIdentity as String],
                    let identity = sec_identity_create(importItemIdentity as! SecIdentity) else {
                        return nil
                }
                
                let options = NWProtocolTLS.Options()
                sec_protocol_options_set_local_identity(options.securityProtocolOptions, identity)
                sec_protocol_options_append_tls_ciphersuite(options.securityProtocolOptions, tls_ciphersuite_t.RSA_WITH_AES_128_GCM_SHA256)
                
                return options
            }
        }
        
        public class Client {
            public let publicKeyHash: String
            private let dispatchQueue = DispatchQueue(label: "ConnectionParameters.TLS.Client.dispatchQueue")
            
            public init(publicKeyHash: String) {
                self.publicKeyHash = publicKeyHash
            }
            
            // Attempt to verify pinned certificate.
            public var options: NWProtocolTLS.Options {
                let options = NWProtocolTLS.Options()
                
                sec_protocol_options_set_verify_block(options.securityProtocolOptions, { secProtocolMetadata, secTrust, secProtocolVerifyComplete in
                    let trust = sec_trust_copy_ref(secTrust).takeRetainedValue()
                    
                    guard let serverCertificate = SecTrustGetCertificateAtIndex(trust, 0) else {
                        secProtocolVerifyComplete(false)
                        return
                    }
                    
                    let serverPublicKey = SecCertificateCopyKey(serverCertificate)
                    let serverPublicKeyData = SecKeyCopyExternalRepresentation(serverPublicKey!, nil)! as Data
                    let keyHash = self.cryptoKitSHA256(data: serverPublicKeyData)
                    
                    if keyHash == self.publicKeyHash {
                        // Presented certificate matches the pinned cert.
                        secProtocolVerifyComplete(true)
                    } else {
                        // Presented certificate doesn't match.
                        secProtocolVerifyComplete(false)
                    }
                }, dispatchQueue)
                
                return options
            }
            
            private func cryptoKitSHA256(data: Data) -> String {
                let rsa2048Asn1Header: [UInt8] = [
                   0x30, 0x82, 0x01, 0x22, 0x30, 0x0d, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86,
                   0xf7, 0x0d, 0x01, 0x01, 0x01, 0x05, 0x00, 0x03, 0x82, 0x01, 0x0f, 0x00
                ]
                
                let data = Data(rsa2048Asn1Header) + data
                let hash = SHA256.hash(data: data)
                
                return Data(hash).base64EncodedString()
            }
        }
    }
}
