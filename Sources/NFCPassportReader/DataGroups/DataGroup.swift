//
//  DataGroup.swift
//
//  Created by Andy Qua on 01/02/2021.
//

import Foundation

@available(iOS 13, macOS 10.15, *)
// FACEKOM:: MODIFICATION BEGIN
open class DataGroup {
    open var datagroupType : DataGroupId { .Unknown }
// FACEKOM:: MODIFICATION END

    
    /// Body contains the actual data
    public private(set) var body : [UInt8] = []
    
    /// Data contains the whole DataGroup data (as that is what the hash is calculated from
    public private(set) var data : [UInt8] = []

// FACEKOM:: MODIFICATION BEGIN
    public private(set) var pos = 0

    required public init( _ data : [UInt8] ) throws {
// FACEKOM:: MODIFICATION END
        self.data = data
        
        // Skip the first byte which is the header byte
        pos = 1
        let _ = try getNextLength()
        self.body = [UInt8](data[pos...])
        
        try parse(data)
    }
// FACEKOM:: MODIFICATION BEGIN
    open func parse( _ data:[UInt8] ) throws {
    }
    
    public func getNextTag() throws -> Int {
// FACEKOM:: MODIFICATION END
        var tag = 0
        
        // Fix for some passports that may have invalid data - ensure that we do have data!
        guard data.count > pos else {
            throw NFCPassportReaderError.TagNotValid
        }

        if binToHex(data[pos]) & 0x0F == 0x0F {
            tag = Int(binToHex(data[pos..<pos+2]))
            pos += 2
        } else {
            tag = Int(data[pos])
            pos += 1
        }
        return tag
    }
// FACEKOM:: MODIFICATION BEGIN
    public func getNextLength() throws -> Int  {
// FACEKOM:: MODIFICATION END
        let end = pos+4 < data.count ? pos+4 : data.count
        let (len, lenOffset) = try asn1Length([UInt8](data[pos..<end]))
        pos += lenOffset
        return len
    }
// FACEKOM:: MODIFICATION BEGIN
    public func getNextValue() throws -> [UInt8] {
// FACEKOM:: MODIFICATION END
        let length = try getNextLength()
        let value = [UInt8](data[pos ..< pos+length])
        pos += length
        return value
    }
    
    public func hash( _ hashAlgorythm: String ) -> [UInt8]  {
        var ret : [UInt8] = []
        if hashAlgorythm == "SHA1" {
            ret = calcSHA1Hash(self.data)
        } else if hashAlgorythm == "SHA224" {
            ret = calcSHA224Hash(self.data)
        } else if hashAlgorythm == "SHA256" {
            ret = calcSHA256Hash(self.data)
        } else if hashAlgorythm == "SHA384" {
            ret = calcSHA384Hash(self.data)
        } else if hashAlgorythm == "SHA512" {
            ret = calcSHA512Hash(self.data)
        }
        
        return ret
    }

    public func verifyTag(_ tag: Int, equals expectedTag: Int) throws {
        if tag != expectedTag  {
            throw NFCPassportReaderError.InvalidResponse(
                dataGroupId: datagroupType,
                expectedTag: expectedTag,
                actualTag: tag
            )
        }
    }

    public func verifyTag(_ tag: Int, oneOf expectedTags: [Int]) throws {
        if !expectedTags.contains(tag) {
            throw NFCPassportReaderError.InvalidResponse(
                dataGroupId: datagroupType,
                expectedTag: expectedTags.first!,
                actualTag: tag
            )
        }
    }
}
